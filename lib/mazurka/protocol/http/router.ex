defmodule Mazurka.Protocol.HTTP.Router do
  @moduledoc """
  A DSL for mazurka resources
  """

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      import Mazurka.Protocol.HTTP.Router
      @before_compile Mazurka.Protocol.HTTP.Router

      use Mazurka.Protocol.HTTP.Request
      use Plug.Builder

      defp match(conn, _opts) do
        {mod, params} = do_match(conn.method, conn.path_info, conn.host)
        conn
        |> Plug.Conn.put_private(:mazurka_route, mod)
        |> Plug.Conn.put_private(:mazurka_params, params)
      end

      def resolve(mod) do
        resolve(mod, %{})
      end

      defp dispatch(%Plug.Conn{assigns: assigns} = conn, _opts) do
        route = Map.get(conn.private, :mazurka_route)
        params = Map.get(conn.private, :mazurka_params)
        Mazurka.Protocol.HTTP.Router.__handle__(route, params, conn)
      end

      defoverridable [match: 2, dispatch: 2]

      ## Build a graph of the resources and their links
      Mazurka.Protocol.HTTP.Router.get "/__graph__", Mazurka.Protocol.HTTP.Graph
      Module.delete_attribute __MODULE__, :mazurka_nodes
      Module.delete_attribute __MODULE__, :mazurka_links
      Module.register_attribute __MODULE__, :mazurka_nodes, accumulate: true
      Module.register_attribute __MODULE__, :mazurka_links, accumulate: true
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    tests = Mazurka.Resource.Test.get_tests(env.module)
    test_mod = if Mix.env == :test do
      quote do
        defmodule Tests do
          tests = unquote(Macro.escape(tests))
          defmacro __using__(_) do
            tests = unquote(Macro.escape(tests))
            quote do
              import ExUnit.Callbacks
              import ExUnit.Assertions
              import ExUnit.Case
              import ExUnit.DocTest
              unquote(tests)
            end
          end
        end
      end
    end
    quote do
      import Mazurka.Protocol.HTTP.Router, only: []
      unquote(test_mod)

      @doc """
      Get a graph object of all of the resources and their links
      """
      def graph() do
        %{
          "nodes" => @mazurka_nodes,
          "links" => @mazurka_links
        }
      end

      def resolve(_, _) do
        {:error, :not_found}
      end
    end
  end

  defmacro match(path, options, contents \\ []) do
    options = options |> Mazurka.Compiler.Utils.eval(__CALLER__)
    contents = contents |> Mazurka.Compiler.Utils.eval(__CALLER__)
    compile(nil, path, options, contents)
  end
  for method <- [:get, :post, :put, :patch, :delete, :options, :head] do
    defmacro unquote(method)(path, options, contents \\ []) do
      options = options |> Mazurka.Compiler.Utils.eval(__CALLER__)
      contents = contents |> Mazurka.Compiler.Utils.eval(__CALLER__)
      compile(unquote(method), path, options, contents)
    end
  end

  ## TODO use forward macro from Plug.Router.forward

  @doc false
  def __route__(method, path, guards, options) do
    {method, guards} = build_methods(List.wrap(method || options[:via]), guards)
    {vars, match}   = Plug.Router.Utils.build_path_match(path)
    {map_params, list_params} = format_params(vars)
    {method, match, map_params, list_params, Plug.Router.Utils.build_host_match(options[:host]), guards}
  end

  def format_params(vars) do
    map_params = Enum.map(vars, fn(var) ->
      {:erlang.list_to_binary(:erlang.atom_to_list(var)), {var, [], nil}}
    end)
    list_params = Enum.map(vars, fn(var) ->
      {var, [], nil}
    end)
    {{:%{}, [], map_params}, list_params}
  end

  @doc false
  def __resolve__(method, path, _host) do
    {format_method(method),
     format_path(path), []}
  end

  defp format_method({:_, _, _}), do: "GET"
  defp format_method(method), do: method

  defp format_path({:_path, _, _}), do: []
  defp format_path(path), do: path

  def __handle__(mod, _params, conn) do
    accepts = Plug.Conn.get_req_header(conn, "accept") |> Mazurka.Protocol.HTTP.AcceptHeader.handle()
    dispatch = conn.private[:mazurka_dispatch]

    apply(mod, :action, [conn, &dispatch.resolve/7, accepts])
    |> handle_resource_resp(conn)
  end

  defp handle_resource_resp({:ok, body, conn, content_type}, _) do
    conn
    |> Plug.Conn.put_resp_content_type(content_type)
    |> handle_transition()
    |> handle_invalidations()
    |> handle_response(body)
  end
  defp handle_resource_resp({:error, :unacceptable}, conn) do
    conn
    |> Plug.Conn.send_resp(:not_acceptable, "Not Acceptable")
  end

  defp handle_transition(%Plug.Conn{private: %{mazurka_transition: location}, status: status} = conn) do
    ## https://en.wikipedia.org/wiki/HTTP_303
    conn = Plug.Conn.put_resp_header(conn, "location", location)
    status = status || 303
    %{conn | status: status}
  end
  defp handle_transition(conn) do
    conn
  end

  defp handle_invalidations(%Plug.Conn{private: %{mazurka_invalidations: invalidations}} = conn) do
    Enum.reduce(invalidations, conn, &(put_resp_header(&2, "x-invalidates", &1)))
  end
  defp handle_invalidations(conn) do
    conn
  end

  defp handle_response(conn, nil) do
    status == conn.status || 204
    Plug.Conn.send_resp(conn, status, "")
  end
  defp handle_response(conn, body) do
    Plug.Conn.send_resp(conn, choose_status(conn), body)
  end

  defp choose_status(%Plug.Conn{private: %{mazurka_error: true}, status: status}) do
    status || 500
  end
  defp choose_status(%Plug.Conn{status: status}) do
    status || 200
  end

  defp put_resp_header(%Plug.Conn{resp_headers: headers} = conn, key, value) do
    %{conn | resp_headers: [{key, value} | headers]}
  end

  defp compile(method, expr, options, contents) do
    {mod, options} =
      cond do
        is_atom(options) ->
          {options, []}
        is_atom(contents) ->
          {contents, options}
        true ->
          raise ArgumentError, message: "expected module handler to be an atom"
    end

    {path, guards} = extract_path_and_guards(expr)

    matches = quote bind_quoted: [method: method,
                        path: path,
                        options: options,
                        guards: Macro.escape(guards, unquote: true),
                        mod: mod] do
      {method, match, map_params, list_params, host, guards} = Mazurka.Protocol.HTTP.Router.__route__(method, path, guards, options)
      {res_method, res_match, res_host} = Mazurka.Protocol.HTTP.Router.__resolve__(method, match, host)
      defp do_match(unquote(method), unquote(match), unquote(host)) when unquote(guards) do
        {unquote(mod), unquote(map_params)}
      end

      def resolve(unquote(mod), unquote(map_params) = params) do
        has_values = Enum.all?(params, fn
          ({_, nil}) -> false
          ({_, :undefined}) -> false
          ({_, _}) -> true
        end)
        if has_values do
          {:ok, unquote(res_method), unquote(res_match)}
        else
          {:error, :not_found}
        end
      end
      def resolve(unquote(mod), unquote(list_params) = params) do
        has_values = Enum.all?(params, fn
          (nil) -> false
          (:undefined) -> false
          (_) -> true
        end)
        if has_values do
          {:ok, unquote(res_method), unquote(res_match)}
        else
          {:error, :not_found}
        end
      end
    end

    is_elixir_module = mod |> to_string |> String.downcase |> String.to_atom != mod

    info = if is_elixir_module do
      quote do
        require unquote(mod)

        ## TODO Include valid params from the mod
        ## TODO Include linked resources from the mod

        ## Auto include resource tests
        :erlang.function_exported(unquote(mod), :tests, 1) and unquote(mod).tests(__MODULE__)

        Module.put_attribute __MODULE__, :mazurka_nodes, %{
          "name" => unquote(mod) |> Module.split |> Enum.join("."),
          "path" => unquote(path)
        }
      end
    end

    [matches, info]
  end

  # Convert the verbs given with `:via` into a variable and guard set that can
  # be added to the dispatch clause.
  defp build_methods([], guards) do
    {quote(do: _), guards}
  end

  defp build_methods([method], guards) do
    {Plug.Router.Utils.normalize_method(method), guards}
  end

  defp build_methods(methods, guards) do
    methods = Enum.map methods, &Plug.Router.Utils.normalize_method(&1)
    var     = quote do: method
    guards  = join_guards(quote(do: unquote(var) in unquote(methods)), guards)
    {var, guards}
  end

  defp join_guards(fst, true), do: fst
  defp join_guards(fst, snd),  do: (quote do: unquote(fst) and unquote(snd))

  # Extract the path and guards from the path.
  defp extract_path_and_guards({:when, _, [path, guards]}), do: {extract_path(path), guards}
  defp extract_path_and_guards(path), do: {extract_path(path), true}

  defp extract_path({:_, _, var}) when is_atom(var), do: "/*_path"
  defp extract_path(path), do: path
end

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
        Plug.Conn.put_private(conn, :mazurka_route, mod)
         |> Plug.Conn.put_private(:mazurka_params, params)
      end

      def resolve(mod) do
        resolve(mod, %{})
      end

      def resolve(mod, params) do
        try do
          do_resolve(mod, params)
        rescue
          _ ->
            {:error, :not_found}
        end
      end

      defp dispatch(%Plug.Conn{assigns: assigns} = conn, _opts) do
        route = Map.get(conn.private, :mazurka_route)
        params = Map.get(conn.private, :mazurka_params)
        Mazurka.Protocol.HTTP.Router.__handle__(route, params, conn)
      end

      defoverridable [match: 2, dispatch: 2]
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
    try do
      {:ok, body, conn, content_type} = apply(mod, :action, [conn, &dispatch.resolve/7, accepts])
      conn
      |> put_resp_header("content-type", content_type)
      |> Plug.Conn.send_resp(choose_status(conn), body)
    rescue
      e in CaseClauseError ->
        case e do
          %CaseClauseError{term: {:error, :not_found}} ->
            Plug.Conn.send_resp(conn, 404, ~S({"error":{"message":"not found!","status": 404}}))
        end
    end
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

      defp do_resolve(unquote(mod), unquote(map_params)) do
        {:ok, unquote(res_method), unquote(res_match)}
      end
      defp do_resolve(unquote(mod), unquote(list_params)) do
        {:ok, unquote(res_method), unquote(res_match)}
      end
    end

    tests = quote do
      require unquote(mod)
      :erlang.function_exported(unquote(mod), :tests, 1) and unquote(mod).tests(__MODULE__)
    end

    [matches, tests]
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

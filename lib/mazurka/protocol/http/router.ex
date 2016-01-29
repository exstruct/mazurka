defmodule Mazurka.Protocol.HTTP.Router do
  @moduledoc """
  A DSL for mazurka resources
  """

  @doc false
  defmacro __using__(opts) do
    quote location: :keep do
      use Mazurka.Protocol.HTTP.Router.Tests
      import Mazurka.Protocol.HTTP.Router
      @before_compile Mazurka.Protocol.HTTP.Router

      use Mazurka.Protocol.HTTP.Request
      use Plug.Builder, unquote(opts)

      defp match(conn, _opts) do
        case do_match(conn.method, conn.path_info) do
          {:ok, mod, params} when is_tuple(mod) ->
            conn
            |> Plug.Conn.put_private(:mazurka_route, elem(mod, 0))
            |> Plug.Conn.put_private(:mazurka_resource, mod)
            |> Plug.Conn.put_private(:mazurka_params, params)
          {:ok, mod, params} ->
            conn
            |> Plug.Conn.put_private(:mazurka_route, mod)
            |> Plug.Conn.put_private(:mazurka_resource, mod)
            |> Plug.Conn.put_private(:mazurka_params, params)
        end
      end

      def resolve(mod) do
        resolve(mod, %{})
      end

      defp dispatch(%Plug.Conn{private: %{mazurka_route: route}} = conn, _opts) do
        Mazurka.Protocol.HTTP.Router.Handler.__handle__(conn, route)
      end

      defoverridable [match: 2, dispatch: 2]
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      import Mazurka.Protocol.HTTP.Router, only: []
      def resolve(_, _) do
        {:error, :not_found}
      end

      def params(_) do
        {:error, :not_found}
      end

      defp do_resolve(method, params) do
        has_values = Enum.all?(params, fn
          (nil) -> false
          (:undefined) -> false
          (_) -> true
        end)

        if has_values do
          {:ok, method, params}
        else
          {:error, :not_found}
        end
      end
    end
  end

  @doc """
  Main API to define routes.

  It accepts an expression representing the path and many options
  allowing the match to be configured.

  ## Examples
      match "/foo/bar", Api.Resource.Foo.Bar
  """
  defmacro match(path, target \\ []) do
    compile(nil, path, target)
  end

  for method <- [:get, :post, :put, :patch, :delete, :options, :head] do
    @doc """
    Dispatches to the path only if the request is a #{Plug.Router.Utils.normalize_method(method)} request.
    See `match/3` for more examples.
    """
    defmacro unquote(method)(path, target \\ []) do
      compile(unquote(method), path, target)
    end
  end

  @doc false
  def __route__(method, path) do
    method = method && Plug.Router.Utils.normalize_method(method) || quote(do: _)
    {vars, match} = Plug.Router.Utils.build_path_match(path)
    {params, map_params, list_params} = format_params(vars)
    {method, match, params, {:%{}, [], map_params}, list_params}
  end

  @doc false
  def __resolve__(method, path) do
    {format_method(method),
     format_path(path)}
  end

  defp format_method({:_, _, _}), do: "GET"
  defp format_method(method), do: method

  defp format_path({:_path, _, _}), do: []
  defp format_path(path), do: path

  defp format_params(vars) do
    vars
    |> Enum.reverse()
    |> Enum.reduce({[], [], []}, fn(var, {params, map_params, list_params}) ->
      v = {var, [], nil}
      {[to_string(var) | params], [{to_string(var), v} | map_params], [v | list_params]}
    end)
  end

  defp compile(method, {:_, _, _}, target) do
    compile(method, "/*_path", target)
  end
  defp compile(method, path, target) do
    quote bind_quoted: [method: method,
                        path: path,
                        target: target] do
      {method, match, params, map_params, list_params} = Mazurka.Protocol.HTTP.Router.__route__(method, path)
      defp do_match(unquote(method), unquote(match)) do
        {:ok, unquote(target), unquote(map_params)}
      end

      {resolve_method, resolve_match} = Mazurka.Protocol.HTTP.Router.__resolve__(method, match)
      def resolve(unquote(target), unquote(map_params)) do
        do_resolve(unquote(resolve_method), unquote(resolve_match))
      end
      def resolve(unquote(target), unquote(list_params)) do
        do_resolve(unquote(resolve_method), unquote(resolve_match))
      end

      def params(unquote(target)) do
        {:ok, unquote(params)}
      end

      Mazurka.Protocol.HTTP.Router.Tests.register_tests(target, __MODULE__)
    end
  end
end

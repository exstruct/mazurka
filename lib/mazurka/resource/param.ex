defmodule Mazurka.Resource.Param do
  defmacro param(name, opts \\ []) do
    Mazurka.Compiler.Utils.register(__MODULE__, name, opts)
  end

  @doc false
  def compile_global(params, _env) do
    params = params
    |> Enum.map(&compile_param/1)

    quote do
      defstruct unquote(params)
    end
  end

  def compile(params, _env) do
    Enum.reduce(params, [], &compile_assign/2)
  end

  defp compile_param({{name, _, _}, _opts}) when is_atom(name) do
    compile_param({name, nil})
  end
  defp compile_param({name, _opts}) when is_atom(name) do
    {name, nil}
  end

  defp compile_assign({name, opts}, acc) when is_atom(name) do
    compile_assign({Macro.var(name, nil), opts}, acc)
  end
  defp compile_assign({name, [do: block]}, acc) do
    expr = quote do
      unquote(Macro.var(:value, nil)) = Params.get(unquote(to_string(elem(name, 0))))
      unquote(block)
    end

    [quote do
      unquote(name) = unquote(expr)
    end | acc]
  end
  defp compile_assign(_, acc) do
    acc
  end

  @doc false
  def format(ast, type \\ :prop) do
    Macro.postwalk(ast, fn
      ({{:., _, [{:__aliases__, _, [:Params]}, :get]}, _, []}) ->
        case type do
          :prop ->
            quote do
              prop(:params)
            end
          :conn ->
            quote do
              ^^Mazurka.Resource.Param.get()
            end
        end
      ({{:., _, [{:__aliases__, _, [:Params]}, :get]}, _, [param]}) ->
        case type do
          :prop ->
            quote do
              ^Dict.get(prop(:params), unquote(param))
            end
          :conn ->
            quote do
              ^^Mazurka.Resource.Param.get(unquote(param))
            end
        end
      (other) ->
        other
    end)
  end

  @doc false
  def get([], conn, _parent, _ref, _attrs) do
    params = Map.get(conn.private, :mazurka_params)
    {:ok, params}
  end
  def get([name], conn, _parent, _ref, _attrs) do
    params = Map.get(conn.private, :mazurka_params)
    val = Map.get(params, name)
    normalized = if val == nil, do: :undefined, else: URI.decode(val)
    {:ok, normalized}
  end
end

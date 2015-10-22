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
      unquote(Macro.var(:value, nil)) = Params.get(unquote(name_to_binary(name)))
      unquote(block)
    end

    [quote do
      unquote(name) = unquote(expr)
    end | acc]
  end
  defp compile_assign({name, _}, acc) do
    [quote do
      unquote(name) = Params.get(unquote(name_to_binary(name)))
    end | acc]
  end

  defp name_to_binary({name, _meta, _context}) when is_atom(name) do
    to_string(name)
  end
  defp name_to_binary(name) when is_atom(name) do
    to_string(name)
  end

  @doc false
  def format(ast, type \\ :prop) do
    Mazurka.Compiler.Utils.postwalk(ast, fn
      ({{:., _, [{:__aliases__, _, [:Params]}, :get]}, _, []}) ->
        get(type)
      ({{:., _, [params, :get]}, _, []}) when params in [:Params, Elixir.Params, __MODULE__] ->
        get(type)
      ({{:., _, [{:__aliases__, _, [:Params]}, :get]}, _, [name]}) ->
        get(name, type)
      ({{:., _, [params, :get]}, _, [name]}) when params in [:Params, Elixir.Params, __MODULE__] ->
        get(name, type)
      (other) ->
        other
    end)
  end

  defp get(:prop) do
    {:etude_prop, [], [:params]}
  end
  defp get(:conn) do
    quote do
      ^^Mazurka.Resource.Param.get()
    end
  end
  defp get(name, :prop) do
    quote do
      ^Dict.get(unquote({:etude_cond, [], [get(:prop), [do: get(:prop), else: {:%{}, [], []}]]}), unquote(name))
    end
  end
  defp get(name, :conn) do
    quote do
      ^^Mazurka.Resource.Param.get(unquote(name))
    end
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

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
  def format({{:., _, [{:__aliases__, _, [:Params]}, :get]}, _, []}, type) do
    get(type)
  end
  def format({{:., _, [params, :get]}, _, []}, type) when params in [:Params, Elixir.Params, __MODULE__] do
    get(type)
  end
  def format({{:., _, [{:__aliases__, _, [:Params]}, :get]}, _, [name]}, type) do
    get(type, name)
  end
  def format({{:., _, [params, :get]}, _, [name]}, type) when params in [:Params, Elixir.Params, __MODULE__] do
    get(type, name)
  end
  def format(other, _type) do
    other
  end

  defp get(:prop) do
    {:etude_prop, [], [:params]}
  end
  defp get(:conn) do
    quote do
      ^^Mazurka.Resource.Param.get()
    end
  end
  defp get(:prop, name) do
    quote do
      ^Mazurka.Runtime.get_param(unquote(get(:prop)), unquote(name))
    end
  end
  defp get(:conn, name) do
    quote do
      ^^Mazurka.Resource.Param.get(unquote(name))
    end
  end

  @doc false
  def get([], %{private: %{mazurka_params: params}}, _parent, _ref, _attrs) do
    {:ok, params}
  end
  def get([name], %{private: %{mazurka_params: params}}, _parent, _ref, _attrs) do
    val = Map.get(params, name)
    normalized = if val == nil, do: :undefined, else: URI.decode(val)
    {:ok, normalized}
  end
end

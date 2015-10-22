defmodule Mazurka.Resource.Input do
  @doc false
  def format(ast, type \\ :prop) do
    Mazurka.Compiler.Utils.postwalk(ast, fn
      ({{:., _, [{:__aliases__, _, [:Input]}, :get]}, _, []}) ->
        get(type)
      ({{:., _, [input, :get]}, _, []}) when input in [:Input, Elixir.Input, __MODULE__] ->
        get(type)
      ({{:., _, [{:__aliases__, _, [:Input]}, :get]}, _, [name]}) ->
        get(name, type)
      ({{:., _, [input, :get]}, _, [name]}) when input in [:Input, Elixir.Input, __MODULE__] ->
        get(name, type)
      (other) ->
        other
    end)
  end

  defp get(:prop) do
    {:etude_prop, [], [:query]}
  end
  defp get(:conn) do
    quote do
      ^^Mazurka.Resource.Input.get()
    end
  end
  defp get(name, :prop) do
    quote do
      ^Dict.get(unquote({:etude_cond, [], [get(:prop), [do: get(:prop), else: {:%{}, [], []}]]}), unquote(name))
    end
  end
  defp get(name, :conn) do
    quote do
      ^^Mazurka.Resource.Input.get(unquote(name))
    end
  end

  @doc false
  def get([], conn, _, _, _) do
    conn = Plug.Conn.fetch_query_params(conn)
    {:ok, conn.params, conn}
  end
  def get([name], conn, _, _, _) do
    conn = Plug.Conn.fetch_query_params(conn)
    value = Dict.get(conn.params, name)
    normalized = if value == nil, do: :undefined, else: value
    {:ok, normalized, conn}
  end
end

defmodule Mazurka.Resource.Input do
  @doc false
  def format(ast, type \\ :prop) do
    Macro.postwalk(ast, fn
      ({{:., _, [{:__aliases__, _, [:Input]}, :get]}, _, []}) ->
        case type do
          :prop ->
            quote do
              prop(:query)
            end
          :conn ->
            quote do
              ^^Mazurka.Resource.Input.get()
            end
        end
      ({{:., _, [{:__aliases__, _, [:Input]}, :get]}, _, [name]}) ->
        case type do
          :prop ->
            quote do
              ^Dict.get(prop(:query), unquote(name))
            end
          :conn ->
            quote do
              ^^Mazurka.Resource.Input.get(unquote(name))
            end
        end
      (other) ->
        other
    end)
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

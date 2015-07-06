defmodule Mazurka.Runtime.Input do
  def get([], conn, _, _, _) do
    conn = Plug.Conn.fetch_query_params(conn)
    {:ok, conn.params, conn}
  end
  def get([name], conn, _, _, _) do
    conn = Plug.Conn.fetch_query_params(conn)
    value = Dict.get(conn.params, name)
    {:ok, value, conn}
  end
end
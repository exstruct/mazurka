defmodule MazurkaTest.Services.Auth do
  def user_id(conn) do
    conn = Plug.Conn.fetch_query_params(conn)
    {:ok, Dict.get(conn.query_params, "auth")}
  end
end

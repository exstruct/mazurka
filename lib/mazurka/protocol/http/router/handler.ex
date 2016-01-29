defmodule Mazurka.Protocol.HTTP.Router.Handler do
  def __handle__(conn, module) do
    accepts = Plug.Conn.get_req_header(conn, "accept") |> Mazurka.Protocol.HTTP.AcceptHeader.handle()
    dispatch = conn.private[:mazurka_dispatch]

    module.action(conn, &dispatch.resolve/7, accepts)
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
    status = conn.status || 204
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
end

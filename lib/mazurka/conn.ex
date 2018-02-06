defprotocol Mazurka.Conn do
  def accepts(conn)
  def put_content_type(conn, mediatype)
  def get_content_type(conn)
  def send_resp(conn, buffer)
end

if Code.ensure_compiled?(Plug.Conn) do
  defimpl Mazurka.Conn, for: Plug.Conn do
    @accepts_cache :"#{inspect(__MODULE__)}.accepts"
    @content_type :"#{inspect(__MODULE__)}.content_type"

    def accepts(%{private: %{@accepts_cache => accepts}} = conn) do
      {accepts, conn}
    end

    def accepts(conn) do
      accepts =
        conn
        |> Plug.Conn.get_req_header("accept")
        |> Stream.map(&Plug.Conn.Utils.list/1)
        |> Stream.concat()
        |> Stream.flat_map(fn type ->
          case Plug.Conn.Utils.media_type(type) do
            {:ok, type, subtype, params} ->
              [{type, subtype, parse_q(params)}]

            _ ->
              []
          end
        end)
        |> Enum.sort(fn
          {_, _, %{"q" => a}}, {_, _, %{"q" => b}} ->
            a >= b

          _, _ ->
            true
        end)

      {accepts, Plug.Conn.put_private(conn, @accepts_cache, accepts)}
    end

    defp parse_q(%{"q" => q} = params) do
      case Float.parse(q) do
        {q, ""} ->
          %{params | "q" => q}

        _ ->
          1.0
      end
    end

    defp parse_q(params) do
      Map.put(params, "q", 1.0)
    end

    def put_content_type(conn, {primary, secondary, _params} = content_type) do
      mediatype = primary <> "/" <> secondary

      conn
      |> Plug.Conn.put_resp_content_type(mediatype)
      |> Plug.Conn.put_private(@content_type, content_type)
    end

    def get_content_type(%{private: %{@content_type => content_type}}) do
      content_type
    end

    def send_resp(conn, buffer) when buffer === [] or buffer === "" do
      Plug.Conn.send_resp(conn, 204, [])
    end

    def send_resp(conn, buffer) do
      Plug.Conn.send_resp(conn, 200, buffer)
    end
  end
end

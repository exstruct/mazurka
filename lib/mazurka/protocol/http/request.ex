defmodule Mazurka.Protocol.Http.Request do
  defmacro __using__(_) do
    quote do
      defmacro request(block) do
        quote do
          require Mazurka.Protocol.Request
          import Mazurka.Protocol.Http.Request
          import unquote(__MODULE__)
          conn = Mazurka.Protocol.Request.request(nil, unquote(block))
          unquote(__MODULE__).request_call(conn, [])
        end
      end

      def request_call(conn, opts) do
        conn = %{conn | adapter: {Mazurka.Protocol.Http.Request, %{}},
                        scheme: "http"}
        case conn.private do
          %{mazurka_route: route} when route != nil ->
            params = Dict.get(conn.private, :mazurka_params, %{})
            {:ok, method, path} = __MODULE__.resolve(route, params)
            conn = %{conn | path_info: path,
                            method: method}
            __MODULE__.call(conn, opts)
          _ ->
            __MODULE__.call(conn, opts)
        end
      end
    end
  end

  for method <- [:get, :post, :put, :patch, :delete, :options, :head] do
    defmacro unquote(method)(path) do
      method = unquote(method)
      quote do
        method(unquote(method))
        path(unquote(path))
      end
    end
  end

  def send_resp(_payload, status, headers, body) do
    body = body |> to_string
    {:ok, body, %{
      status: status,
      headers: headers,
      body: body
    }}
  end
end
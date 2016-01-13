defmodule Mazurka.Protocol.Request do

  defmacro request(resource, [do: block]) do
    quote do
      import unquote(__MODULE__)
      var!(conn) = %Plug.Conn{adapter: {Mazurka.Protocol.Request, %{}},
                              owner: self(),
                              port: 80,
                              peer: {{127, 0, 0, 1}, 111317},
                              remote_ip: {127, 0, 0, 1},
                              params: %{},
                              query_params: %{},
                              req_headers: [{"accept", "*/*"}],
                              private: %{mazurka_route: unquote(resource)}}
      unquote(block)
      var!(conn)
    end
  end

  # for method <- [:get, :post, :put, :patch, :delete, :options, :head] do
  #   defmacro unquote(method)(path) do
  #     method = unquote(method)
  #     quote do
  #       method(unquote(method))
  #       path(unquote(path))
  #     end
  #   end
  # end

  defmacro method(method) do
    method = method |> to_string |> String.upcase
    quote do
      var!(conn) = %{var!(conn) | method: unquote(method)}
    end
  end

  defmacro host(host) do
    quote do
      var!(conn) = %{var!(conn) | host: unquote(host)}
    end
  end

  defmacro path(path) do
    quote do
      info = Mazurka.Protocol.Request.split_path(unquote(path))
      var!(conn) = %{var!(conn) | path_info: info}
    end
  end

  defmacro params(params) do
    quote do
      params = Mazurka.Resource.Link.unwrap_ids(unquote(params))
      var!(conn) = Plug.Conn.put_private(var!(conn), :mazurka_params, params)
    end
  end

  defmacro query(query) do
    quote do
      query = case unquote(query) do
        q when is_binary(q) ->
          Plug.Conn.Query.decode(query)
        q when is_map(q) ->
          Mazurka.Resource.Link.unwrap_ids(q)
      end

      params = var!(conn).params
      query_params = var!(conn).query_params

      var!(conn) = %{var!(conn) |
                     params: Dict.merge(query_params, query),
                     query_params: Dict.merge(query_params, query)}
    end
  end

  defmacro query(key, value) do
    quote do
      params = var!(conn).params
      query_params = var!(conn).query_params
      var!(conn) = %{var!(conn) |
                     params: Dict.put(query_params, to_string(unquote(key)), to_string(unquote(value))),
                     query_params: Dict.put(query_params, to_string(unquote(key)), to_string(unquote(value)))}
    end
  end

  defmacro body(_content) do
    # TODO
    quote do
      # var!(conn) = %{var!(conn) | }
    end
  end

  defmacro header(kvs) do
    quote do
      headers = var!(conn).req_headers
      kvs = Enum.map(unquote(kvs), fn {k, v} -> {to_string(k), to_string(v)} end)
      var!(conn) = %{var!(conn) | req_headers: unquote(kvs) ++ headers}
    end
  end

  defmacro header(key, value) do
    quote do
      headers = var!(conn).req_headers
      var!(conn) = %{var!(conn) | req_headers: [{to_string(unquote(key)), to_string(unquote(value))} | headers]}
    end
  end

  defmacro accept(subtype) when subtype in ["html", "plain", "css"] do
    quote do
      accept("text", unquote(subtype))
    end
  end
  defmacro accept(subtype) do
    {type, subtype} = case subtype |> to_string |> String.split("/") do
      [subtype] ->
        {"application", subtype}
      [type, subtype] ->
        {type, subtype}
    end

    quote do
      accept(unquote(type), unquote(subtype))
    end
  end

  defmacro accept(type, subtype, _params \\ %{}) do
    ## TODO send params
    accept = "#{type}/#{subtype}"
    quote do
      header("accept", unquote(accept))
    end
  end

  defmacro ip(ip) do
    ip = cond do
      is_binary(ip) ->
        {:ok, ip} = ip |> String.to_char_list |> :inet.parse_address
        ip
      is_tuple(ip) ->
        ip
    end
    |> Macro.escape
    quote do
      var!(conn) = %{var!(conn) | remote_ip: unquote(ip)}
    end
  end

  ## Helpers

  def send_resp(req, status, headers, body) do
    req = Map.merge(req, %{
      status: status,
      resp_headers: headers,
      resp_body: :erlang.iolist_to_binary(body)
    })
    {:ok, nil, req}
  end

  def merge_resp(conn = %{adapter: {__MODULE__, state}}) do
    Map.merge(conn, state)
  end

  def split_path(path) do
    segments = :binary.split(path, "/", [:global])
    for segment <- segments, segment != "", do: segment
  end
end

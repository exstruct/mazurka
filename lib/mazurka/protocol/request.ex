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
      var!(conn) = Plug.Conn.put_private(var!(conn), :mazurka_params, unquote(params))
    end
  end

  defmacro query(query) do
    query = Mazurka.Compiler.Utils.eval(query, __CALLER__)
    query = cond do
      is_binary(query) ->
        Plug.Conn.Query.decode(query)
      is_map(query) ->
        query
    end
    |> Macro.escape
    quote do
      params = var!(conn).query_params
      var!(conn) = %{var!(conn) | query_params: Dict.merge(params, unquote(query))}
    end
  end

  defmacro query(key, value) do
    quote do
      params = var!(conn).query_params
      var!(conn) = %{var!(conn) | query_params: Dict.put(params, unquote(key), unquote(value))}
    end
  end

  defmacro body(_content) do
    # TODO
    quote do
      # var!(conn) = %{var!(conn) | }
    end
  end

  defmacro header(kvs) do
    kvs = kvs
    |> Mazurka.Compiler.Utils.eval(__CALLER__)
    |> Enum.map(fn({key, value}) ->
      {to_string(key), to_string(value)}
    end)
    |> Macro.escape

    quote do
      headers = var!(conn).req_headers
      var!(conn) = %{var!(conn) | req_headers: unquote(kvs) ++ headers}
    end
  end

  defmacro header(key, value) do
    quote do
      headers = var!(conn).req_headers
      var!(conn) = %{var!(conn) | req_headers: [{unquote(key), unquote(value)} | headers]}
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

  def split_path(path) do
    segments = :binary.split(path, "/", [:global])
    for segment <- segments, segment != "", do: segment
  end
end

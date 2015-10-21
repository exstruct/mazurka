defmodule Mazurka.Resource.Link do
  @moduledoc """
  Represents a link in a response. This is used by mediatypes to serialize the link in the appropriate
  format. It's broken into its separate parts (method, host, path, etc.) for easy manipulation.
  """

  defstruct mediatype: nil,
            method: nil,
            scheme: nil,
            host: nil,
            port: nil,
            path: nil,
            query: nil,
            fragment: nil

  def compile(_opts, _env) do
    nil
  end

  def format_params(nil) do
    {:%{}, [], []}
  end
  def format_params({:%{}, meta, items}) do
    {:%{}, meta, Enum.map(items, fn({name, value}) ->
      {to_string(name), value}
    end)}
  end
  def format_params(items) when is_list(items) do
    {:%{}, [], Enum.map(items, fn({name, value}) ->
      {to_string(name), value}
    end)}
  end

  def link_to(args, _conn, _parent, _ref, _attrs) do
    try do
      [module, params, query, fragment] = unwrap_args(args)

      props = %{params: params, query: query, fragment: fragment}
      ## FOR BACKWARDS COMPATIBILITY - remove once markdown is removed
      |> Dict.merge(params)
      |> Dict.merge(%{"_params" => params, "_query" => query, "_fragment" => fragment})

      {:partial, {module, :affordance_partial, props}}
    catch
      {:undefined_param, _} ->
        {:ok, :undefined}
    end
  end

  def transition_to([href, _, nil, nil], %{private: private} = conn, _parent, _ref, _attrs) when is_binary(href) do
    {:ok, nil, %{conn | private: Dict.put(private, :mazurka_transition, href)}}
  end
  def transition_to(args, conn, parent, ref, attrs) do
    case args |> unwrap_args |> resolve(conn, parent, ref, attrs) do
      {:ok, :undefined} ->
        {:error, :transition_to_unknown_location}
      {:ok, affordance} ->
        [to_string(affordance), nil, nil, nil]
        |> transition_to(conn, parent, ref, attrs)
    end
  end

  def invalidates([href, _, nil, nil], %{private: private} = conn, _parent, _ref, _attrs) when is_binary(href) do
    invalidations = Map.get(private, :mazurka_invalidations, [])
    {:ok, nil, %{conn | private: Map.put(private, :mazurka_invalidations, [href | invalidations])}}
  end
  def invalidates(args, conn, parent, ref, attrs) do
    case args |> unwrap_args |> resolve(conn, parent, ref, attrs) do
      {:ok, :undefined} ->
        {:error, :invalidates_unknown_location}
      {:ok, affordance} ->
        [to_string(affordance), nil, nil, nil]
        |> invalidates(conn, parent, ref, attrs)
    end
  end

  defp unwrap_args([module, params, query, fragment]) do
    [module, unwrap_ids(params), unwrap_ids(query), fragment]
  end

  defp unwrap_ids(kvs) when kvs in [nil, :undefined] do
    kvs
  end
  defp unwrap_ids(kvs) do
    Enum.reduce(kvs, %{}, fn
      ({key, %{"id" => id}}, acc) ->
        Map.put(acc, to_string(key), to_string(id))
      ({key, %{id: id}}, acc) ->
        Map.put(acc, to_string(key), to_string(id))
      ({key, value}, _) when value in [nil, :undefined] ->
        throw {:undefined_param, key}
      ({key, value}, acc) ->
        Map.put(acc, to_string(key), to_string(value))
    end)
  end

  def encode_qs(params) do
    out = Enum.filter_map(params, fn({_k, v}) ->
      case v do
        nil -> false
        :undefined -> false
        false -> false
        "" -> false
        _ -> true
      end
    end, fn({k, v}) ->
      [k, "=", URI.encode_www_form(v)]
    end)
    |> Enum.join("&")

    if out == "" do
      nil
    else
      out
    end
  end

  def resolve([module, params, query, fragment], %{private: private} = conn, _parent, _ref, _attrs) do
    %{mazurka_router: router, mazurka_mediatype_handler: mediatype_module} = private
    case router.resolve(module, params) do
      {:ok, method, scheme, host, path} ->
        {:ok, %__MODULE__{mediatype: mediatype_module,
                          method: method,
                          scheme: scheme,
                          host: host,
                          port: conn.port,
                          path: request_path(%{conn | path_info: path}),
                          query: query,
                          fragment: fragment}}
      {:ok, method, path} ->
        {:ok, %__MODULE__{mediatype: mediatype_module,
                          method: method,
                          scheme: conn.scheme,
                          host: conn.host,
                          port: conn.port,
                          path: request_path(%{conn | path_info: path}),
                          query: query,
                          fragment: fragment}}
      {:error, :not_found} ->
        {:ok, :undefined}
    end
  end

  def from_conn(%{private: %{mazurka_mediatype_handler: mediatype_module}} = conn) do
    %__MODULE__{mediatype: mediatype_module,
                method: conn.method,
                scheme: conn.scheme,
                host: conn.host,
                port: conn.port,
                path: request_path(conn),
                query: conn.query_string}
  end
  def from_conn(conn, path_info) do
    from_conn(%{conn | path_info: path_info})
  end

  defp request_path(%{script_name: [], path_info: []}) do
    "/"
  end
  defp request_path(%{script_name: script, path_info: path}) do
    "/" <> Enum.join(script ++ path, "/")
  end
end

defimpl String.Chars, for: Mazurka.Resource.Link do
  def to_string(%{fragment: fragment, host: host, method: method, path: path, port: port, query: query, scheme: scheme}) do
    %URI{fragment: format_fragment(fragment),
         host: host,
         path: format_path(path),
         port: port,
         query: format_query(query, method),
         scheme: Kernel.to_string(scheme)}
    |> Kernel.to_string
  end

  defp format_path(nil), do: nil
  defp format_path(""), do: nil
  defp format_path([]), do: nil
  defp format_path("/"), do: nil
  defp format_path(path) when is_list(path), do: "/" <> Enum.join(path, "/")
  defp format_path(path), do: Kernel.to_string(path)

  defp format_query(_, method) when method in ["POST", "PUT", "PATCH"], do: nil
  defp format_query(nil, _), do: nil
  defp format_query("", _), do: nil
  defp format_query(%{__struct__: _} = qs, _), do: Kernel.to_string(qs)
  defp format_query(qs, _) when is_map(qs), do: Mazurka.Resource.Link.encode_qs(qs)
  defp format_query(qs, _), do: Kernel.to_string(qs)

  defp format_fragment(nil), do: nil
  defp format_fragment([]), do: nil
  defp format_fragment(fragment) when is_list(fragment), do: "/" <> Enum.join(fragment, "/")
  defp format_fragment(fragment), do: Kernel.to_string(fragment)
end

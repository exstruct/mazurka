defmodule Mazurka.Resource.Link do
  @moduledoc """
  Represents a link in a response. This is used by mediatypes to serialize the link in the appropriate
  format. It's broken into its separate parts (method, host, path, etc.) for easy manipulation.
  """

  require Mazurka.Resource.Link.Assertions

  defstruct resource: nil,
            mediatype: nil,
            method: nil,
            scheme: nil,
            host: nil,
            port: nil,
            path: nil,
            query: nil,
            persistent_query: nil,
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

  def link_to(args, conn, _parent, _ref, _attrs) do
    try do
      [resource, params, query, fragment] = unwrap_args(args, conn)

      props = %{resource: resource, params: params, query: query, fragment: fragment}
      ## FOR BACKWARDS COMPATIBILITY - remove once markdown is removed
      |> Dict.merge(params)
      |> Dict.merge(%{"_params" => params, "_query" => query, "_fragment" => fragment})

      Mazurka.Resource.Link.Assertions.link_to(resource, props, conn)
    catch
      {:undefined_param, _} ->
        {:ok, :undefined}
    end
  end

  def transition_to([{:href, href}, _, nil, nil], %{private: private} = conn, _parent, _ref, _attrs) when is_binary(href) do
    {:ok, nil, %{conn | private: Dict.put(private, :mazurka_transition, href)}}
  end
  def transition_to(args, conn, parent, ref, attrs) do
    case args |> unwrap_args(conn) |> resolve(conn, parent, ref, attrs) do
      {:ok, :undefined} ->
        {:error, :transition_to_unknown_location}
      {:ok, affordance} ->
        [{:href, to_string(affordance)}, nil, nil, nil]
        |> transition_to(conn, parent, ref, attrs)
    end
  end

  def invalidates([{:href, href}, _, nil, nil], %{private: private} = conn, _parent, _ref, _attrs) when is_binary(href) do
    invalidations = Map.get(private, :mazurka_invalidations, [])
    {:ok, nil, %{conn | private: Map.put(private, :mazurka_invalidations, [href | invalidations])}}
  end
  def invalidates(args, conn, parent, ref, attrs) do
    case args |> unwrap_args(conn) |> resolve(conn, parent, ref, attrs) do
      {:ok, :undefined} ->
        {:error, :invalidates_unknown_location}
      {:ok, affordance} ->
        [{:href, to_string(affordance)}, nil, nil, nil]
        |> invalidates(conn, parent, ref, attrs)
    end
  end

  defp unwrap_args([resource, params, query, fragment], %{private: %{mazurka_router: router}}) do
    [
      router.resolve_module(resource) || resource,
      unwrap_ids(params),
      unwrap_ids(query, :ignore),
      fragment
    ]
  end

  def unwrap_ids(kvs, mode \\ :throw)
  def unwrap_ids(kvs, _) when kvs in [nil, :undefined] do
    kvs
  end
  def unwrap_ids(kvs, mode) do
    Enum.reduce(kvs, %{}, fn
      ({key, %{"id" => id}}, acc) ->
        Map.put(acc, to_string(key), to_string(id))
      ({key, %{id: id}}, acc) ->
        Map.put(acc, to_string(key), to_string(id))
      ({key, value}, _) when value in [nil, :undefined] and mode == :throw ->
        throw {:undefined_param, key}
      ({_, value}, acc) when value in [nil, :undefined] ->
        acc
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

  def resolve([resource, params, query, fragment], %{private: %{mazurka_router: router}} = conn, _parent, _ref, _attrs) do
    link = new(resource, query, fragment, conn)

    case router.resolve(resource, params) do
      {:ok, method, path, _resource_params} ->
        %{link | method: method,
                 path: request_path(%{conn | path_info: path})}
        |> apply_link_transform(conn)
      {:error, :not_found} ->
        {:ok, :undefined}
    end
  end

  defp new(resource, query, fragment, %{private: %{mazurka_mediatype_handler: mediatype_module}} = conn) do
    %__MODULE__{
      resource: Mazurka.Resource.Link.Utils.resource_to_module(resource),
      query: query,
      fragment: fragment,
      mediatype: mediatype_module,
      scheme: conn.scheme,
      host: conn.host,
      port: conn.port,
    }
  end

  defp apply_link_transform(link, conn = %{private: %{mazurka_link_transform: {module, function}}}) do
    {:ok, apply(module, function, [link, conn])}
  end
  defp apply_link_transform(link, _) do
    {:ok, link}
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
  def to_string(%{fragment: fragment, host: host, method: method, path: path, port: port, query: query, scheme: scheme} = url) do
    qs = query
    |> format_query(method)
    |> join_query(format_query(Map.get(url, :persistent_query), "GET"))
    %URI{fragment: format_fragment(fragment),
         host: host,
         path: format_path(path),
         port: port,
         query: qs,
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
  defp format_query(qs, _) when map_size(qs) == 0, do: nil
  defp format_query(qs, _) when is_map(qs), do: Mazurka.Resource.Link.encode_qs(qs)
  defp format_query(qs, _), do: Kernel.to_string(qs)

  defp join_query(nil, nil), do: nil
  defp join_query(q, nil), do: q
  defp join_query(nil, q), do: q
  defp join_query(q1, q2), do: q1 <> "&" <> q2

  defp format_fragment(nil), do: nil
  defp format_fragment([]), do: nil
  defp format_fragment(fragment) when is_list(fragment), do: "/" <> Enum.join(fragment, "/")
  defp format_fragment(fragment), do: Kernel.to_string(fragment)
end

defmodule Mazurka.Resource.Link do
  @moduledoc """
  Represents a link in a response. This is used by mediatypes to serialize the link in the appropriate
  format. It's broken into its separate parts (method, host, path, etc.) for easy manipulation.  
  """

  defstruct mediatype: nil,
            props: nil,
            method: nil,
            scheme: nil,
            host: nil,
            path: nil,
            qs: nil,
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

  def link_to([module, params, qs, fragment], _conn, _parent, _ref, _attrs) do
    {:partial, {module, :affordance_partial, %{params: params, qs: qs, fragment: fragment}}}
  end

  def transition_to(args, %{private: private} = conn, parent, ref, attrs) do
    case resolve(args, conn, parent, ref, attrs) do
      {:ok, :undefined} ->
        {:error, :transition_to_unknown_location}
      {:ok, affordance} ->
        location = to_string(affordance)
        {:ok, nil, %{conn | private: Dict.put(private, :mazurka_transition, location)}}
    end
  end

  def encode_qs(params) do
    Enum.filter_map(params, fn({_k, v}) ->
      case v do
        nil -> false
        :undefined -> false
        false -> false
        "" -> false
        _ -> true
      end
    end, fn({k, v}) ->
      [k, "=", URI.encode_www_form(v)]
    end) |> Enum.join("&")
  end

  def resolve([module, params, qs, fragment], %{private: private}, _parent, _ref, _attrs) do
    %{mazurka_router: router, mazurka_mediatype_handler: mediatype_module} = private
    case router.resolve(module, params) do
      {:ok, method, scheme, host, path} ->
        {:ok, %__MODULE__{mediatype: mediatype_module,
                          method: method,
                          scheme: scheme,
                          host: host,
                          path: path,
                          qs: qs,
                          fragment: fragment}}
      {:ok, method, path} ->
        {:ok, %__MODULE__{mediatype: mediatype_module,
                          method: method,
                          path: path,
                          qs: qs,
                          fragment: fragment}}
      {:error, :not_found} ->
        {:ok, :undefined}
    end
  end
end

defimpl String.Chars, for: Mazurka.Resource.Link do
  def to_string(affordance) do
    "#{format_host(affordance.scheme, affordance.host)}#{
       format_path(affordance.path)}#{
       format_qs(affordance.qs)}#{
       format_fragment(affordance.fragment)}"
  end

  defp format_host(_, nil), do: ""
  defp format_host(nil, host), do: "://#{host}"
  defp format_host(scheme, host), do: "#{scheme}://#{host}"

  defp format_path(nil), do: "/"
  defp format_path([]), do: "/"
  defp format_path(path), do: "/" <> Enum.join(path, "/")

  defp format_qs(nil), do: ""
  defp format_qs(qs) when is_map(qs), do: "?#{Mazurka.Resource.Link.encode_qs(qs)}"
  defp format_qs(qs), do: "?#{qs}"

  defp format_fragment(nil), do: ""
  defp format_fragment(fragment), do: "##{fragment}"
end
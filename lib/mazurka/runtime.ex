defmodule Mazurka.Runtime do
  alias Mazurka.Runtime.Affordance

  @mediatype_key :mazurka_mediatype

  def raise([exception], _conn, _parent, _ref, _attrs) do
    {:error, exception}
  end

  def struct([module, props], _context, _parent, _ref, _attrs) do
    if :erlang.function_exported(module, :affordance_partial, 5) do
      {:partial, {module, :affordance_partial, props}}
    else
      {:ok, Kernel.struct(module, props)}
    end
  end

  def resolve_affordance([module, mediatype_module, params, props], %{private: %{mazurka_router: router}} = context, _parent, _ref, _attrs) do
    _mediatype = get_mediatype(context)
    case router.resolve(module, params) do
      {:ok, method, scheme, host, path} ->
        {:ok, %Affordance{mediatype: mediatype_module,
                          props: props,
                          method: method,
                          scheme: scheme,
                          host: host,
                          path: path}}
      {:ok, method, path} ->
        {:ok, %Affordance{mediatype: mediatype_module,
                          props: props,
                          method: method,
                          path: path}}
      {:error, :not_found} ->
        {:ok, :undefined}
    end
  end

  def get_mediatype(context) do
    Dict.get(context.private, @mediatype_key, {nil, nil, nil})
  end

  def put_mediatype(%{private: private} = context, value) do
    %{context | private: Map.put(private, @mediatype_key, value)}
  end
end
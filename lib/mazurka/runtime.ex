defmodule Mazurka.Runtime do

  def raise([exception], _conn, _parent, _ref, _attrs) do
    {:error, exception}
  end

  def get_mediatype(context) do
    Dict.get(context.private, :mazurka_mediatype, {nil, nil, nil})
  end

  def put_mediatype(%{private: private} = context, module, value) do
    private = private
    |> Dict.put(:mazurka_mediatype, value)
    |> Dict.put(:mazurka_mediatype_handler, module)
    %{context | private: private}
  end
end
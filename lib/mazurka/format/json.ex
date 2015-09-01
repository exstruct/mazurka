defmodule Mazurka.Format.JSON do
  def encode(content, opts \\ []) do
    Poison.encode_to_iodata!(content, opts)
  end

  def decode(content, opts \\ []) do
    content
    |> to_string
    |> Poison.decode!(opts)
  end
end

defimpl Poison.Encoder, for: Mazurka.Resource.Link do
  def encode(%{mediatype: mediatype, props: props} = affordance, opts) do
    affordance
    |> mediatype.affordance(props, opts)
    |> Poison.encode!(opts)
  end
end

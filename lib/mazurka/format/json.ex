defmodule Mazurka.Format.JSON do
  def encode(content, opts) do
    Poison.encode!(content, opts)
  end

  def decode(content, opts) do
    Poison.decode!(content, opts)
  end
end

defimpl Poison.Encoder, for: Mazurka.Runtime.Affordance do
  def encode(%{mediatype: mediatype} = affordance, opts) do
    affordance
    |> mediatype.affordance(opts)
    |> Poison.encode!(opts)
  end
end
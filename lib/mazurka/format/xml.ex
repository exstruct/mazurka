defmodule Mazurka.Format.XML do
  def encode(content, _opts \\ []) do
    content
    |> XmlBuilder.doc()
  end

  def decode(_content, _opts \\ []) do
    throw :XML_decode_not_supported
  end
end

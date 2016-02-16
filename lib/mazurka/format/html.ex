defmodule Mazurka.Format.HTML do
  def encode(content, opts \\ []) do
    HTMLBuilder.encode_to_iodata!(content, opts)
  end

  def decode(_content, _opts \\ []) do
    throw :HTML_decode_not_supported
  end
end

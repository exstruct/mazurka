defmodule Mazurka.Format.ERLANG_TERM do
  def encode(content, opts \\ []) do
    :erlang.term_to_binary(content, opts)
  end

  def decode(content, opts \\ []) do
    content
    |> to_string
    |> :erlang.binary_to_term(opts)
  end
end
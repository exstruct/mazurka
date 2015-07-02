defmodule Mazurka.Resource.Error do
  defmacro error(mediatype, name, [do: block]) do
    Mazurka.Compiler.Utils.register(mediatype, __MODULE__, block, name)
  end

  def compile(mediatype, block, globals, meta) do
    quote do
      unquote_splicing(globals[:let] || [])
      response = unquote(block)
      unquote(mediatype).handle_error(response)
    end
  end
end
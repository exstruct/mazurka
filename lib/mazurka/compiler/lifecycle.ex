defprotocol Mazurka.Compiler.Lifecycle do
  @fallback_to_any true
  def format(node, globals, mediatype)
end

defimpl Mazurka.Compiler.Lifecycle, for: Any do
  def format(node, globals, _) do
    quote do
      unquote_splicing(globals.lets)
      unquote(node.block)
    end
  end
end
defprotocol Mazurka.Compiler.Compilable do
  def compile(struct, vars, opts \\ nil)
end

defimpl Mazurka.Compiler.Compilable, for: List do
  def compile([], vars, _) do
    {nil, vars}
  end

  def compile([value], vars, opts) do
    @protocol.compile(value, vars, opts)
  end
end

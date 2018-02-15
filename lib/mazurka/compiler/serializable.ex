defprotocol Mazurka.Compiler.Serializable do
  def compile(struct, vars, impl)
end

defimpl Mazurka.Compiler.Serializable, for: List do
  def compile([], vars, _) do
    {nil, vars}
  end

  def compile([value], vars, impl) do
    @protocol.compile(value, vars, impl)
  end
end

defprotocol Mazurka.Compiler.Scopable do
  def compile(struct, vars)
end

defimpl Mazurka.Compiler.Scopable, for: List do
  def compile(list, vars) do
    Enum.map_reduce(list, vars, &@protocol.compile/2)
  end
end

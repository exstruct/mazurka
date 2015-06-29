defmodule Mazurka.Resource.Definition do
  defstruct block: nil,
            kind: nil

  def handle(block, kind \\ :def) do
    %__MODULE__{block: block,
                kind: kind}
  end
end

defimpl Mazurka.Compiler.Lifecycle, for: Mazurka.Resource.Definition do
  def format(node, _) do
    node.block
  end
end
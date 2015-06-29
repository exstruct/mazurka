defmodule Mazurka.Resource.Affordance do
  defstruct block: nil

  def handle(block) do
    %__MODULE__{block: block}
  end
end

defimpl Mazurka.Compiler.Lifecycle, for: Mazurka.Resource.Affordance do
  def format(node, globals) do
    quote do
      unquote_splicing(globals.lets)
      if unquote(globals.conditions) do
        unquote(node.block)
      end
    end
  end
end
defmodule Mazurka.Resource.Action do
  defstruct block: nil

  def handle(block) do
    %__MODULE__{block: block}
  end
end

defimpl Mazurka.Compiler.Lifecycle, for: Mazurka.Resource.Action do
  def format(node, globals) do
    quote do
      unquote_splicing(globals.lets)
      if unquote(globals.conditions) do
        case unquote(node.block) do
          _ ->
            unquote_splicing(globals.events)
        end
      end
    end
  end
end
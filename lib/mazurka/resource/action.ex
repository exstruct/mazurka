defmodule Mazurka.Resource.Action do
  defstruct block: nil

  def handle(block) do
    %__MODULE__{block: block}
  end
end

defimpl Mazurka.Compiler.Lifecycle, for: Mazurka.Resource.Action do
  def format(node, globals, _mediatype) do
    {:action, quote do
      unquote_splicing(globals.lets)
      __mazurka_action__ = unquote(node.block)
      __mazurka_events__ = unquote_splicing(globals.events || [true])
      if unquote(globals.conditions) do
        ## we're using this if/else for causal tracking
        if __mazurka_action__ do
          __mazurka_events__
          __mazurka_action__
        else
          __mazurka_events__
          __mazurka_action__
        end
      end
    end}
  end
end
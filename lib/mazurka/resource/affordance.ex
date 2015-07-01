defmodule Mazurka.Resource.Affordance do
  defstruct block: nil,
            resource: nil

  def handle(block, resource) do
    %__MODULE__{block: block, resource: resource}
  end
end

defimpl Mazurka.Compiler.Lifecycle, for: Mazurka.Resource.Affordance do
  def format(node, globals, mediatype) do
    block = format_block(node.block)
    params = format_params(globals.params)
    {:affordance, quote do
      unquote_splicing(globals.lets)
      if unquote(globals.conditions) do
        props = unquote(node.block)
        params = unquote(params)
        ^^Mazurka.Runtime.resolve_affordance(unquote(node.resource), unquote(mediatype), params, props)
      end
    end}
  end

  defp format_block(block) when is_list(block) do
    {:__block__, [], block}
  end
  defp format_block(block) do
    block
  end

  defp format_params(params) do
    {:%{}, [], Enum.map(params, fn
      ({{name, _, _}, _}) ->
        quote do
          {unquote(to_string(name)), Param.unquote(name)}
        end
    end)}
  end
end

defmodule Mazurka.Resource.Affordance do
  defmacro affordance(mediatype, [do: block]) do
    Mazurka.Compiler.Utils.register(mediatype, __MODULE__, block, nil)
  end

  def compile(mediatype, block, globals, meta) do
    quote do
      unquote_splicing(globals[:let] || [])
      affordance = unquote(block)

      failure = unquote(globals[:condition])

      if failure do
        :undefined
      else
        :TODO
      end
    end
  end
end

# defimpl Mazurka.Compiler.Lifecycle, for: Mazurka.Resource.Affordance do
#   def format(node, globals, mediatype) do
#     block = format_block(node.block)
#     params = format_params(globals.params)
#     {:affordance, quote do
#       unquote_splicing(globals.lets)
#       if unquote(format_params_check(globals.params)) && unquote(globals.conditions) do
#         props = unquote(block)
#         params = unquote(params)
#         ^^Mazurka.Runtime.resolve_affordance(unquote(node.resource), unquote(mediatype), params, props)
#       else
#         :undefined
#       end
#     end}
#   end

#   defp format_block(block) when is_list(block) do
#     {:__block__, [], block}
#   end
#   defp format_block(block) do
#     block
#   end

#   defp format_params(params) do
#     {:%{}, [], Enum.map(params, fn
#       ({{name, _, _}, _}) ->
#         quote do
#           {unquote(to_string(name)), Param.unquote(name)}
#         end
#     end)}
#   end

#   def format_params_check(params) do
#     Enum.reduce(params, nil, fn
#       ({{name, _, _}, _}, nil) ->
#         quote do
#           Param.unquote(name)
#         end
#       ({{name, _, _}, _}, acc) ->
#         quote do
#           Param.unquote(name) && unquote(acc)
#         end
#     end) || true
#   end
# end

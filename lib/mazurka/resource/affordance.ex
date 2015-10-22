defmodule Mazurka.Resource.Affordance do
  defmacro affordance(mediatype, [do: block]) do
    Mazurka.Compiler.Utils.register(mediatype, __MODULE__, block, __CALLER__.module)
  end

  def default(module) do
    {nil, module}
  end

  def compile(mediatype, block, globals, module) do
    quote do
      unquote_splicing(globals[:param] || [])
      unquote_splicing(globals[:let] || [])
      affordance = ^^Mazurka.Resource.Link.resolve(unquote(module), prop(:params), prop(:query), prop(:fragment))
      affordance_props = unquote(block)
      failure = unquote(globals[:condition] |> Mazurka.Resource.Condition.compile_silent())

      response = unquote(mediatype).handle_affordance(affordance, affordance_props)

      if failure do
        :undefined
      else
        response
      end
    end
    |> Mazurka.Resource.Param.format
    |> Mazurka.Resource.Input.format
  end
end

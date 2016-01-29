defmodule Mazurka.Resource.Action do
  defmacro action(mediatype, [do: block]) do
    Mazurka.Compiler.Utils.register(mediatype, __MODULE__, block, nil)
  end

  def default(_module) do
    {nil, nil}
  end

  def compile(mediatype, block, globals, _meta) do
    quote do
      unquote_splicing(globals[:param] || [])
      unquote_splicing(globals[:let] || [])
      action = unquote(block)
      events = unquote(globals[:event])

      # this may seem redundant but it's used for tracking causality
      # between the event and action
      response = if action do
        events
        action
      else
        events
        action
      end

      condition_failure = unquote(globals[:condition] |> Mazurka.Resource.Condition.compile_fatal())
      validation_failure = unquote(globals[:validation] |> Mazurka.Resource.Validation.compile())

      failure = condition_failure || validation_failure

      if failure do
        raise failure
      else
        unquote(mediatype).handle_action(response)
      end
    end
  end

  def expand(ast, _) do
    Mazurka.Compiler.Utils.postwalk(ast, fn(expr) ->
      expr
      |> Mazurka.Resource.Param.format(:conn)
      |> Mazurka.Resource.Input.format(:conn)
      |> Mazurka.Resource.Resource.format(:conn)
    end)
  end
end

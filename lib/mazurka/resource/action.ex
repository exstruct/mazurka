defmodule Mazurka.Resource.Action do
  defmacro action(mediatype, [do: block]) do
    Mazurka.Compiler.Utils.register(mediatype, __MODULE__, block, nil)
  end

  def compile(mediatype, block, globals, _meta) do
    quote do
      unquote_splicing(globals[:let] || [])
      action = unquote(block)
      events = unquote(globals[:event] || [true])

      # this may seem redundant but it's used for tracking causality
      # between the event and action
      response = if action do
        events
        action
      else
        events
        action
      end

      failure = unquote(globals[:condition])

      if failure do
        raise failure
      else
        unquote(mediatype).handle_action(response)
      end
    end
    |> Mazurka.Resource.Param.format(:conn)
  end
end

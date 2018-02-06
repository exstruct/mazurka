defmodule Mazurka.Resource.Collection do
  @moduledoc false

  defstruct conditions: [],
            expression: nil,
            value: nil,
            line: nil

  # TODO implement this
  defmacro collection(expression, do: block) do
    quote do
      prev = @mazurka_subject

      @mazurka_subject %unquote(__MODULE__){
        expression: unquote(Macro.escape(expression)),
        line: __ENV__.line
      }

      import Mazurka.Resource.{AffordanceFor, Collection, Condition, Map}
      unquote(block)

      %{conditions: conditions} = collection = @mazurka_subject

      collection = %{
        collection
        | conditions: :lists.reverse(conditions)
      }

      @mazurka_subject Mazurka.Builder.put(prev, :value, collection)
    end
  end
end

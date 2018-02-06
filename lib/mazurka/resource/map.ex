defmodule Mazurka.Resource.Map do
  @moduledoc false

  defstruct conditions: [],
            doc: nil,
            fields: [],
            scope: [],
            line: nil

  defmacro map(do: block) do
    quote do
      prev = @mazurka_subject

      @mazurka_subject %unquote(__MODULE__){
        doc: Mazurka.Builder.get_doc(__MODULE__),
        line: __ENV__.line
      }

      import Mazurka.Resource.{Condition, Field}
      unquote(block)
      # import Mazurka.Resource.{Condition, Field}, only: []

      %{conditions: conditions, fields: fields} = map = @mazurka_subject

      map = %{
        map
        | fields: :lists.reverse(fields),
          conditions: :lists.reverse(conditions)
      }

      @mazurka_subject Mazurka.Builder.put(prev, :value, map)
    end
  end
end

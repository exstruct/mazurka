defmodule Mazurka.Resource.Field do
  @moduledoc false

  defstruct conditions: [],
            doc: nil,
            name: nil,
            scope: [],
            value: [],
            line: nil

  defmacro field(name, do: block) do
    quote do
      prev = @mazurka_subject

      @mazurka_subject %unquote(__MODULE__){
        name: unquote(name),
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        line: __ENV__.line
      }

      import Mazurka.Resource.{AffordanceFor, Collection, Condition, Constant, Map, Resolve}
      unquote(block)

      %{conditions: conditions} = field = @mazurka_subject

      field = %{
        field
        | conditions: :lists.reverse(conditions)
      }

      @mazurka_subject Mazurka.Builder.append(prev, :fields, field)
    end
  end
end

defmodule Mazurka.Resource.Input do
  @moduledoc false

  defstruct conditions: [],
            doc: nil,
            info: %{},
            name: nil,
            scope: [],
            validations: [],
            value: [],
            line: nil

  defmacro input(name) do
    input_body(name, nil)
  end

  defmacro input(name, do: body) do
    input_body(name, body)
  end

  defp input_body(name, body) do
    quote do
      prev = @mazurka_subject

      @mazurka_subject %unquote(__MODULE__){
        name: unquote(name),
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        line: __ENV__.line
      }

      import Mazurka.Resource.{Condition, Constant, Resolve, Validate, Validation}
      unquote(body)

      %{conditions: conditions} = input = @mazurka_subject

      input = %{
        input
        | conditions: :lists.reverse(conditions)
      }

      @mazurka_subject Mazurka.Builder.append(prev, :scope, input)
    end
  end
end

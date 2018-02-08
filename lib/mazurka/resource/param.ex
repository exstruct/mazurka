defmodule Mazurka.Resource.Param do
  @moduledoc false

  defstruct doc: nil,
            name: nil,
            scope: [],
            validations: [],
            value: nil,
            line: nil

  defmacro param(name) do
    param_body(name, nil)
  end

  defmacro param(name, do: body) do
    param_body(name, body)
  end

  defp param_body({name, _, context}, body) when is_atom(context) do
    param_body(name, body)
  end

  defp param_body(name, body) do
    quote do
      prev = @mazurka_subject

      @mazurka_subject %unquote(__MODULE__){
        name: unquote(name),
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        line: __ENV__.line
      }

      import Mazurka.Resource.{Condition, Constant, Resolve, Validate}
      unquote(body)

      @mazurka_subject Mazurka.Builder.append(prev, :scope, @mazurka_subject)
    end
  end
end

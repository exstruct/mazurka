defmodule Mazurka.Resource.Constant do
  @moduledoc false

  defstruct value: nil,
            line: nil

  defmacro constant([{:do, value} | _]) do
    constant_body(value)
  end

  defmacro constant(value) do
    constant_body(value)
  end

  defp constant_body(value) do
    quote do
      constant = %unquote(__MODULE__){
        value: unquote(value),
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.append(@mazurka_subject, :value, constant)
    end
  end
end

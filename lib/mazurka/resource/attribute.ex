defmodule Mazurka.Resource.Attribute do
  defstruct name: nil,
            value: nil,
            line: 0

  alias Mazurka.Resource.Builder

  defmacro unquote(:@)({name, _, [value]}) do
    Builder.child(
      quote do
        %unquote(__MODULE__){
          name: unquote(name),
          value: unquote(value),
          line: __ENV__.line
        }
      end
    )
  end
end

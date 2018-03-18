defmodule Mazurka.Resource.Body.Constant do
  defstruct value: nil,
            line: 0

  alias Mazurka.Resource.{Builder, Body}

  defmacro constant(do: body) do
    Builder.child(
      quote do
        %unquote(__MODULE__){
          value: unquote(body)
        }
      end,
      nil,
      quote do
        import unquote(Body).{}
      end
    )
  end
end

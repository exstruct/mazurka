defmodule Mazurka.Resource.Input.Map do
  defstruct children: [],
            line: 0

  alias Mazurka.Resource.{Builder, Input}

  defmacro map(do: body) do
    Builder.child(
      __MODULE__,
      body,
      quote do
        import unquote(Input).{
          Field
        }
      end
    )
  end
end

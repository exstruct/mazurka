defmodule Mazurka.Resource.Body.Map do
  defstruct children: [],
            line: 0

  alias Mazurka.Resource.{Builder, Body}

  defmacro map(do: body) do
    Builder.child(
      __MODULE__,
      body,
      quote do
        import unquote(Body).{
          Field
        }
      end
    )
  end
end

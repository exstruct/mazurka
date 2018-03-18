defmodule Mazurka.Resource.Action.Map do
  defstruct children: [],
            line: 0

  alias Mazurka.Resource.{Builder, Action}

  defmacro map(do: body) do
    Builder.child(
      __MODULE__,
      body,
      quote do
        import unquote(Action).{
          Field
        }
      end
    )
  end
end

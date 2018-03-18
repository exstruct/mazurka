defmodule Mazurka.Resource.Input.Field do
  defstruct name: nil,
            children: [],
            line: 0

  alias Mazurka.Resource.{Builder, Input}

  defmacro field(name, do: body) do
    Builder.child(
      quote do
        %unquote(__MODULE__){name: unquote(name)}
      end,
      body,
      quote do
        import unquote(Input).{
          Default,
          # Validate,
          Validation
        }
      end
    )
  end
end

defmodule Mazurka.Resource.Action.Field do
  defstruct name: nil,
            children: [],
            line: 0

  alias Mazurka.Resource.{Builder, Action}

  defmacro field(name, do: body) do
    Builder.child(
      quote do
        %unquote(__MODULE__){name: unquote(name)}
      end,
      body,
      quote do
        import unquote(Action).{}
      end
    )
  end
end

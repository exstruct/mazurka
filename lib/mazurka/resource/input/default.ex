defmodule Mazurka.Resource.Input.Default do
  defstruct body: nil,
            line: 0

  alias Mazurka.Resource.{Builder}

  defmacro default(do: body) do
    Builder.child(
      quote do
        %unquote(__MODULE__){
          body: unquote(Macro.escape(body))
        }
      end
    )
  end
end

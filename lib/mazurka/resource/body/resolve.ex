defmodule Mazurka.Resource.Body.Resolve do
  defstruct value: nil,
            line: 0

  alias Mazurka.Resource.{Builder, Body}

  defmacro resolve(do: body) do
    Builder.child(
      quote do
        %unquote(__MODULE__){
          value: unquote(Macro.escape(body))
        }
      end,
      nil,
      quote do
        import unquote(Body).{}
      end
    )
  end
end

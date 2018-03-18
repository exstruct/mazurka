defmodule Mazurka.Resource.Body.Collection do
  defstruct items: nil,
            item: nil,
            children: [],
            line: 0

  alias Mazurka.Resource.{Builder, Body}

  defmacro collection({:<-, _, [item, items]}, do: body) do
    Builder.child(
      quote do
        %unquote(__MODULE__){
          items: unquote(Macro.escape(items)),
          item: unquote(Macro.escape(item))
        }
      end,
      body,
      quote do
        import unquote(Body).{
          Map
        }
      end
    )
  end
end

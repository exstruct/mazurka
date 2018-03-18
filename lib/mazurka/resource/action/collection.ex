defmodule Mazurka.Resource.Action.Collection do
  defstruct items: nil,
            item: nil,
            children: [],
            line: 0

  alias Mazurka.Resource.{Builder, Action}

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
        import unquote(Action).{
          Map
        }
      end
    )
  end
end

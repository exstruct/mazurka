defmodule Mazurka.Resource.Let do
  @moduledoc false
  defstruct code: nil,
            line: 0

  alias Mazurka.Resource.Builder

  defmacro let({:=, _, _} = assign) do
    Builder.child(
      quote do
        %unquote(__MODULE__){
          code: unquote(Macro.escape(assign)),
          line: __ENV__.line
        }
      end
    )
  end

  defmacro let(do: body) do
    Builder.child(
      quote do
        %unquote(__MODULE__){
          code: unquote(Macro.escape(body)),
          line: __ENV__.line
        }
      end
    )
  end
end

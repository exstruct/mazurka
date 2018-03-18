defmodule Mazurka.Resource.Body.Field do
  defstruct name: nil,
            children: [],
            line: 0

  alias Mazurka.Resource.{Builder, Body}

  defmacro field(name, do: body) do
    Builder.child(
      quote do
        %unquote(__MODULE__){name: unquote(name)}
      end,
      body,
      quote do
        import unquote(Body).{}
      end
    )
  end

  defmacro field(name, value) do
    quote do
      unquote(__MODULE__).field unquote(name) do
        resolve do
          unquote(value)
        end
      end
    end
  end
end

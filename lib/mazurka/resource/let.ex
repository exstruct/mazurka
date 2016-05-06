defmodule Mazurka.Resource.Let do
  @moduledoc false

  alias Mazurka.Resource.Utils.Scope

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Define a resource-wide variable

      let foo = 1
  """

  defmacro let({:=, _, [{name, _, _}, block]}) when is_atom(name) do
    Scope.compile(name, block)
  end

  @doc """
  Define a resource-wide variable with a block

      let foo do
        id = Params.get("user")
        User.get(id)
      end
  """

  defmacro let({name, _, _}, [do: block]) when is_atom(name) do
    Scope.compile(name, block)
  end
end

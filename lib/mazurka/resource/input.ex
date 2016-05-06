defmodule Mazurka.Resource.Input do
  @moduledoc false

  use Mazurka.Resource.Utils
  use Mazurka.Resource.Utils.Global, var: :input
  alias Mazurka.Resource.Utils.Scope

  defmacro __using__(_) do
    quote do
      require unquote(__MODULE__)
      alias unquote(__MODULE__)
      import unquote(__MODULE__), only: [input: 1, input: 2]
    end
  end

  @doc """
  Define an expected input for the resource

      input name

      input age, String.to_integer(&value)

      input address do
        Address.parse(&value)
      end
  """

  defmacro input(name, block \\ []) do
    Scope.define(Utils.input, name, block)
  end
end

defmodule Mazurka.Resource.Option do
  @moduledoc false

  use Mazurka.Resource.Utils
  use Mazurka.Resource.Utils.Global, var: :opts, type: :atom
  alias Mazurka.Resource.Utils.Scope

  defmacro __using__(_) do
    quote do
      require unquote(__MODULE__)
      alias unquote(__MODULE__)
      import unquote(__MODULE__), only: [option: 1, option: 2]
    end
  end

  @doc """
  Define an expected option for the resource

      option name

      option age, &String.to_integer(&1)

      option address, fn(value) ->
        Address.parse(value)
      end
  """

  defmacro option(name, block \\ []) do
    Scope.define(Utils.opts, name, block, :atom)
  end
end

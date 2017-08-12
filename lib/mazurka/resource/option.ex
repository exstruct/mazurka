defmodule Mazurka.Resource.Option do
  @moduledoc false

  alias Mazurka.Resource.Utils
  use Utils.Global, var: :opts, type: :atom
  alias Utils.Scope

  defmacro __using__(_) do
    %{module: module} = __CALLER__
    Module.register_attribute(module, :mazurka_options, accumulate: true)
    quote do
      require unquote(__MODULE__)
      alias unquote(__MODULE__)
      import unquote(__MODULE__), only: [option: 1, option: 2]

      def options do
        @mazurka_options
      end
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
    %{module: module} = __CALLER__
    Module.put_attribute(module, :mazurka_options, elem(name, 0))
    Scope.define(Utils.opts, name, block, :atom)
  end
end

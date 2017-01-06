defmodule Mazurka.Resource.Param do
  @moduledoc false

  # expose the params getter
  alias Mazurka.Resource.Utils
  use Utils.Global, var: :params
  alias Utils.Scope

  defmacro __using__(_) do
    quote do
      require unquote(__MODULE__)
      alias unquote(__MODULE__), as: Params
      import unquote(__MODULE__), only: [param: 1, param: 2]

      def __mazurka_check_params__(_) do
        {[], []}
      end
      defoverridable __mazurka_check_params__: 1
    end
  end

  @doc """
  Define an expected parameter for the resource

      param user

      param user, &User.get(&1)

      param user, fn(value) ->
        User.get(value)
      end
  """

  defmacro param(name, block \\ []) do
    bin_name = elem(name, 0) |> to_string()
    [
      Scope.define(Utils.params, name, block),
      quote do
        def __mazurka_check_params__(params) do
          {missing, nil_params} = super(params)
          case Map.fetch(params, unquote(bin_name)) do
            :error ->
              {[unquote(bin_name) | missing], nil_params}
            {:ok, nil} ->
              {missing, [unquote(bin_name) | nil_params]}
            _ ->
              {missing, nil_params}
          end
        end
        defoverridable __mazurka_check_params__: 1
      end
    ]
  end
end

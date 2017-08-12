defmodule Mazurka.Resource.Param do
  @moduledoc false

  # expose the params getter
  alias Mazurka.Resource.Utils
  use Utils.Global, var: :params
  alias Utils.Scope

  defmacro __using__(_) do
    %{module: module} = __CALLER__
    Module.register_attribute(module, :mazurka_params, accumulate: true)
    Module.register_attribute(module, :mazurka_param_checks, accumulate: true)
    quote do
      require unquote(__MODULE__)
      alias unquote(__MODULE__), as: Params
      import unquote(__MODULE__), only: [param: 1, param: 2]

      @before_compile unquote(__MODULE__)

      def params do
        @mazurka_params
      end
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
    bin_name = name |> elem(0) |> to_string()
    %{module: module} = __CALLER__
    Module.put_attribute(module, :mazurka_params, bin_name)
    Module.put_attribute(module, :mazurka_param_checks, bin_name)
    Scope.define(Utils.params, name, block)
  end

  defmacro __before_compile__(env) do
    case Module.get_attribute(env.module, :mazurka_param_checks) do
      [] ->
        quote do
          defp __mazurka_check_params__(_params) do
            {[], []}
          end
        end
      [name] ->
        quote do
          defp __mazurka_check_params__(params) do
            Mazurka.Resource.Param.__check_param__(params, unquote(name), [], [])
          end
        end
      names ->
        checks = Enum.map(names, fn(name) ->
          quote do
            {missing, nil_params} = Mazurka.Resource.Param.__check_param__(params, unquote(name), missing, nil_params)
          end
        end)
        quote do
          defp __mazurka_check_params__(params) do
            missing = []
            nil_params = []
            unquote_splicing(checks)
            {missing, nil_params}
          end
        end
    end
  end

  def __check_param__(params, name, missing, nil_params) do
    case Map.fetch(params, name) do
      :error ->
        {[name | missing], nil_params}
      {:ok, nil} ->
        {missing, [name | nil_params]}
      _ ->
        {missing, nil_params}
    end
  end
end

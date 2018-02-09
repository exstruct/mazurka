defmodule Mazurka.Resource.AffordanceFor do
  @moduledoc false

  # TODO format the args better
  defstruct module: nil,
            params: %{},
            inputs: %{},
            line: nil

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro affordance_for(module) do
    affordance_for_body(module, [], [])
  end

  defmacro affordance_for(module, params) do
    affordance_for_body(module, params, [])
  end

  defmacro affordance_for(module, params, inputs) do
    affordance_for_body(module, params, inputs)
  end

  defp affordance_for_body(module, {:%{}, _, params}, inputs) do
    affordance_for_body(module, params, inputs)
  end

  defp affordance_for_body(module, params, {:%{}, _, inputs}) do
    affordance_for_body(module, params, inputs)
  end

  defp affordance_for_body(module, params, inputs) when is_list(params) and is_list(inputs) do
    quote do
      link = %unquote(__MODULE__){
        module: unquote(module),
        params: %{
          unquote_splicing(Enum.map(params, &Macro.escape/1))
        },
        inputs: %{
          unquote_splicing(Enum.map(inputs, &Macro.escape/1))
        },
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.append(@mazurka_subject, :value, link)
    end
  end
end

defmodule Mazurka.Resource.Condition do
  def attribute do
    :mz_condition
  end

  defmacro condition(block, error_handler \\ nil) do
    Mazurka.Resource.Utils.save(__CALLER__, attribute, format(block, error_handler))
  end

  defp format(block, nil) do
    quote do
      if !unquote(block) do
        raise %Mazurka.Resource.PreconditionError{}
      else
        true
      end
    end
  end
  defp format(block, {error_handler, _, _}) do
    quote do
      if !unquote(block) do
        unquote(error_handler)(%Mazurka.Resource.PreconditionError{})        
      else
        true
      end
    end
  end
end
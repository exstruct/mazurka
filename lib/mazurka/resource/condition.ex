defmodule Mazurka.Resource.Condition do
  def attribute do
    :mz_condition
  end

  defmacro condition(block, error_handler \\ nil)
  defmacro condition(block, error_handler) when not is_list(block) do
    handle([block], error_handler, __CALLER__)
  end
  defmacro condition(block, error_handler) do
    handle(block, error_handler, __CALLER__)
  end

  defp handle(block, error_handler, caller) do
    Mazurka.Resource.Utils.save(caller, attribute, format(block, error_handler))
  end

  defp format(block, nil) do
    quote do
      if !unquote_splicing(block) do
        raise %Mazurka.Resource.PreconditionError{}
      else
        true
      end
    end
  end
  defp format(block, {error_handler, _, _}) do
    quote do
      if !unquote_splicing(block) do
        unquote(error_handler)(%Mazurka.Resource.PreconditionError{})        
      else
        true
      end
    end
  end
end
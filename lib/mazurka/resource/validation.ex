defmodule Mazurka.Resource.Validation.Failure do
  defexception [:message]
end

defmodule Mazurka.Resource.Validation do
  defmacro validation(block, error_handler \\ nil)
  defmacro validation([do: block], error_handler) do
    Mazurka.Compiler.Utils.register(__MODULE__, block, error_handler)
  end
  defmacro validation(block, error_handler) do
    Mazurka.Compiler.Utils.register(__MODULE__, block, error_handler)
  end

  def compile(conditions) do
    conditions = Enum.map(conditions || [], &(handle_condition(&1)))

    quote do
      conditions = unquote(conditions)
      ^Mazurka.Resource.Validation.handle_error(conditions)
    end
  end

  def compile(conditions, _) do
    conditions
  end

  defp handle_condition({block, {error_handler, _, _}}) when is_atom(error_handler) do
    compile_condition(block, error_handler)
  end
  defp handle_condition({block, nil}) do
    compile_condition(block, :error)
  end

  defp compile_condition(block, error_handler) do
    code = Macro.to_string(block)
    message = "Validation failure of #{inspect(code)}"

    quote do
      condition = unquote(block)
      if !condition do
        error = %Mazurka.Resource.Validation.Failure{message: unquote(message)}
        message = %__MODULE__.unquote(error_handler){error: error}
        %Mazurka.Resource.Error{
          message: message
        }
      end
    end
  end

  def handle_error(errors) do
    Enum.find(errors, fn
      (nil) -> false
      (_) -> true
    end)
  end
end

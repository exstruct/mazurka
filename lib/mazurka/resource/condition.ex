defmodule Mazurka.Resource.Condition.Failure do
  defexception [:message]
end

defmodule Mazurka.Resource.Condition do
  defmacro condition(block, error_handler \\ nil)
  defmacro condition([do: block], error_handler) do
    Mazurka.Compiler.Utils.register(__MODULE__, block, error_handler)
  end
  defmacro condition(block, error_handler) do
    Mazurka.Compiler.Utils.register(__MODULE__, block, error_handler)
  end

  def compile(conditions, _env) do
    conditions
  end

  def compile_fatal(conditions) do
    compile_type(conditions, :fatal)
  end

  def compile_silent(conditions) do
    compile_type(conditions, :silent)
  end

  defp compile_type(conditions, type) do
    conditions = Enum.map(conditions || [], &(handle_condition(&1, type)))

    quote do
      conditions = unquote(conditions)
      ^Mazurka.Resource.Condition.handle_error(conditions)
    end
  end

  defp handle_condition({block, {error_handler, _, _}}, type) when is_atom(error_handler) do
    compile_condition(block, error_handler, type)
  end
  defp handle_condition({block, nil}, type) do
    compile_condition(block, :error, type)
  end

  defp compile_condition(block, error_handler, :fatal) do
    code = Macro.to_string(block)
    message = "Condition failure of #{inspect(code)}"

    quote do
      condition = unquote(block)
      if !condition do
        error = %Mazurka.Resource.Condition.Failure{message: unquote(message)}
        message = %__MODULE__.unquote(error_handler){error: error}
        %Mazurka.Resource.Error{
          message: message
        }
      end
    end
  end
  defp compile_condition(block, _, :silent) do
    quote do
      condition = unquote(block)
      if !condition do
        true
      end
    end
  end

  def generic_error(_) do

  end

  def handle_error(errors) do
    Enum.find(errors, fn
      (nil) -> false
      (_) -> true
    end)
  end
end

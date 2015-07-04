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
    conditions = Enum.map(conditions, fn({block, {error_handler, _, _}}) when is_atom(error_handler) ->
      code = Macro.to_string(block)
      message = "Condition failure of #{inspect(code)}"

      quote do
        if !unquote(block) do
          err = %Mazurka.Resource.Condition.Failure{message: unquote(message)}
          message = %__MODULE__.unquote(error_handler){err: err}
          %Mazurka.Resource.Error{
            message: message
          }
        end
      end
    end)

    quote do
      ^Mazurka.Resource.Condition.handle_error(unquote(conditions))
    end
  end

  def handle_error(errors) do
    Enum.find(errors, fn
      (nil) -> false
      (error) -> error
    end)
  end
end
defmodule Mazurka.Resource.Condition do
  defmacro condition(block, error_handler \\ nil) do
    Mazurka.Compiler.Utils.register(__MODULE__, block, error_handler)
  end

  def compile(conditions) do
    IO.inspect {:CONDITIONS, conditions}
    false
  end
end
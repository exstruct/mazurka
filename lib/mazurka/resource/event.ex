defmodule Mazurka.Resource.Event do
  defmacro event([do: block]) do
    Mazurka.Compiler.Utils.register(__MODULE__, block)
  end

  def compile(events) do
    Enum.map(events, fn({ast, _meta}) ->
      ast
    end)
  end
end
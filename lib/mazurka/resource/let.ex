defmodule Mazurka.Resource.Let do
  defmacro let({:=, _meta, [_name, _block]} = node) do
    store(node)
  end

  defmacro let(name, [do: block]) do
    {:=, [], [name, block]}
    |> store
  end

  defp store(block) do
    Mazurka.Compiler.Utils.register(__MODULE__, block)
  end

  def compile(lets) do
    Enum.map(lets, fn({ast, _meta}) ->
      ast
    end)
  end
end
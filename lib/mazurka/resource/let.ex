defmodule Mazurka.Resource.Let do
  defmacro let({:=, _meta, [_name, _block]} = node) do
    store(node)
  end

  defmacro let({:=, meta, [name, {call, call_meta, call_args}]}, clauses) do
    {:=, meta, [name, {call, call_meta, call_args ++ [clauses]}]}
    |> store
  end
  defmacro let(name, [do: body]) do
    {:=, [], [name, body]}
    |> store
  end

  defp store(block) do
    Mazurka.Compiler.Utils.register(__MODULE__, block)
  end

  def compile(lets, _env) do
    Enum.map(lets, fn({ast, _meta}) ->
      ast
    end)
  end
end

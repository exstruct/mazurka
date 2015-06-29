defmodule Mazurka.Compiler.Utils do
  def eval(quoted, env) do
    {out, []} = quoted
    |> Macro.expand(env)
    |> Code.eval_quoted([], env)
    out
  end
end
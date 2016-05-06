defmodule Mazurka.Utils do
  @moduledoc false

  def eval(quoted, env) do
    {out, []} = quoted
    |> Macro.expand(env)
    |> Code.eval_quoted([], env)
    out
  end

  def prewalk(quoted, fun) do
    Macro.prewalk(quoted, walk(fun, &prewalk(&1, fun)))
  end

  def postwalk(quoted, fun) do
    Macro.postwalk(quoted, walk(fun, &postwalk(&1, fun)))
  end

  defp walk(fun, recurse) do
    fn
      ({:__block__, meta, children}) ->
        {:__block__, meta, Enum.map(children, recurse)}
      ([{:do, _} | _] = doblock) ->
        Enum.map(doblock, fn({key, children}) ->
          children = recurse.(children)
          {key, children}
        end)
        |> fun.()
      ({name, children}) when is_atom(name) ->
        children = recurse.(children)
        {name, children}
        |> fun.()
      (other) ->
        other
        |> fun.()
    end
  end
end

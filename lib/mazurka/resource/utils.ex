defmodule Mazurka.Resource.Utils do
  def expand([do: ast], env) do
    expand(ast, env)
  end
  def expand({:__block__, meta, children}, env) do
    {:__block__, meta, Enum.map(children, &(expand(&1, env)))}
  end
  def expand(ast, env) do
    Macro.expand(ast, env)
  end
end
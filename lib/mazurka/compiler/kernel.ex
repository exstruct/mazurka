defmodule Mazurka.Compiler.Kernel do
  def wrap(block) do
    {:__block__, [],
     [{:import, [],
       [{:__aliases__, [alias: false], [:Kernel]}, [only: [], warn: false]]},
      {:import, [],
       [{:__aliases__, [alias: false], [:Mazurka, :Compiler, :Kernel]}, [warn: false]]},
      block]}
  end

  defmacro if(expression, arms) do
    {:etude_cond, [], [expression, arms]}
  end

  defmacro raise(expression) do
    quote do
      ^^Mazurka.Runtime.raise(unquote(expression))
    end
  end

  defmacro left or right do
    {:etude_cond, [], [left, [do: left, else: right]]}
  end

  defmacro left and right do
    {:etude_cond, [], [left, [do: false, else: right]]}
  end

  ## TODO implement the rest of these
end
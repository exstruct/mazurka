defmodule Mazurka.Resource.Let do
  def attribute do
    :mz_let
  end

  defmacro let(name, [do: block]) do
    Mazurka.Resource.Utils.save(__CALLER__, attribute, format(name, block))
  end

  defp format(name, block) do
    {:=, [], [name, block]}
  end
end
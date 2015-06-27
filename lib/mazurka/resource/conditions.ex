defmodule Mazurka.Resource.Conditions do
  defmacro conditions(block) do
    Mazurka.Resource.Utils.expand(block, __CALLER__)
  end
end
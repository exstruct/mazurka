defmodule Mazurka.Resource.Scope do
  import Mazurka.Resource.Define

  defmacro scope(name, block) do
    quote do
      mz_defp unquote(name) do
        unquote(block)
      end
    end
  end
end
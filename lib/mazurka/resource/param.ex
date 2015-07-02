defmodule Mazurka.Resource.Param do
  defmacro param(name, opts \\ []) do
    Mazurka.Compiler.Utils.register(__MODULE__, name, opts)
  end

  def compile(params) do
    IO.inspect {:params, params}
    []
  end
end
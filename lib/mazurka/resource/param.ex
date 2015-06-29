defmodule Mazurka.Resource.Param do
  def attribute do
    :mz_param
  end

  defmacro param(name, opts \\ []) do
    Mazurka.Resource.Utils.save(__CALLER__, attribute, {name, opts})
  end
end
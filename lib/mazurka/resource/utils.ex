defmodule Mazurka.Resource.Utils do
  def save(caller, name, value) do
    module = caller.module
    Module.register_attribute(module, name, accumulate: true)
    Module.put_attribute(module, name, value)
    nil
  end
end
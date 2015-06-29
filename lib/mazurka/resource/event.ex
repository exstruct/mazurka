defmodule Mazurka.Resource.Event do
  def attribute do
    :mz_event
  end

  defmacro event(block) do
    Mazurka.Resource.Utils.save(__CALLER__, attribute, block)
  end
end
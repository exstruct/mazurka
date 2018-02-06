defmodule Mazurka.Mediatype do
  @moduledoc false

  defstruct provides: [],
            serializer: nil

  def provides(%{provides: provides}) do
    provides
  end

  def action(%{serializer: serializer}, subject, vars) do
    subject
    |> serializer.action(vars)
  end

  def affordance(%{serializer: serializer}, subject, vars) do
    subject
    |> serializer.affordance(vars)
  end

  def key(%{serializer: serializer}) do
    serializer
  end
end

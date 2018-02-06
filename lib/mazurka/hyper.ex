defmodule Mazurka.Hyper do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use unquote(__MODULE__).JSON
      use unquote(__MODULE__).Msgpack
    end
  end

  def action(subject) do
    subject
  end

  def affordance(subject) do
    subject
  end
end

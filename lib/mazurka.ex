defmodule Mazurka do
  @moduledoc """
  """

  @doc """

  """
  defmacro __using__(_opts) do
    quote do
      use Mazurka.Resource
    end
  end
end

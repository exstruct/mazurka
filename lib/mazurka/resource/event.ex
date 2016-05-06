defmodule Mazurka.Resource.Event do
  @moduledoc false

  use Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)

      @doc false
      defp event(action, unquote_splicing(arguments)) do
        {action, unquote(conn)}
      end
      defoverridable event: unquote(length(arguments) + 1)
    end
  end

  @doc """
  Create an event block

      event do
        # event goes here
      end
  """

  defmacro event([do: block]) do
    quote location: :keep do
      @doc false
      defp event(action, unquote_splicing(arguments)) do
        {var!(action), var!(conn)} = super(action, unquote_splicing(arguments))
        unquote(block)
        {var!(action), var!(conn)}
      end
      defoverridable event: unquote(length(arguments) + 1)
    end
  end
end

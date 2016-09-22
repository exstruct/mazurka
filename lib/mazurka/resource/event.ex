defmodule Mazurka.Resource.Event do
  @moduledoc false

  use Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)

      @doc false
      def event(action, unquote_splicing(arguments()), unquote(scope())) do
        {action, unquote(conn())}
      end
      defoverridable event: unquote(length(arguments()) + 2)
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
      def event(action, unquote_splicing(arguments()), unquote(scope())) do
        {var!(action), var!(conn)} = super(action, unquote_splicing(arguments()), unquote(scope()))
        unquote(block)
        {var!(action), var!(conn)}
      end
      defoverridable event: unquote(length(arguments()) + 2)
    end
  end
end

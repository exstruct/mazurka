defmodule Mazurka.Resource.Event do
  @moduledoc false

  use Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)

      @doc false
      def __mazurka_event__(action, unquote_splicing(arguments()), unquote(scope()), unquote(mediatype())) do
        {action, unquote(conn())}
      end
      defoverridable __mazurka_event__: unquote(length(arguments()) + 3)
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
      def __mazurka_event__(action, unquote_splicing(arguments()), unquote(scope()), unquote(mediatype())) do
        {var!(action), var!(conn)} = super(action, unquote_splicing(arguments()), unquote(scope()), unquote(mediatype()))
        unquote(block)
        {var!(action), var!(conn)}
      end
      defoverridable __mazurka_event__: unquote(length(arguments()) + 3)
    end
  end
end

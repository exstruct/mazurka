defmodule Mazurka.Resource.Event do
  @moduledoc false

  alias Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)

      @doc false
      def __mazurka_event__(action, unquote_splicing(Utils.arguments), unquote(Utils.scope), unquote(Utils.mediatype)) do
        {action, unquote(Utils.conn)}
      end
      defoverridable __mazurka_event__: unquote(length(Utils.arguments) + 3)
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
      def __mazurka_event__(action, unquote_splicing(Utils.arguments), unquote(Utils.scope), unquote(Utils.mediatype)) do
        {var!(action), var!(conn)} = super(action, unquote_splicing(Utils.arguments), unquote(Utils.scope), unquote(Utils.mediatype))
        Mazurka.Resource.Utils.Scope.dump()
        unquote(block)
        {var!(action), var!(conn)}
      end
      defoverridable __mazurka_event__: unquote(length(Utils.arguments) + 3)
    end
  end
end

defmodule Mazurka.Resource.Event do
  @moduledoc false

  alias Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :mazurka_events, accumulate: true)
      @before_compile unquote(__MODULE__)
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
      @mazurka_events unquote(Macro.escape(block))
    end
  end

  defmacro __before_compile__(env) do
    events = Module.get_attribute(env.module, :mazurka_events) |> :lists.reverse()
    quote do
      defp __mazurka_event__(var!(action), unquote_splicing(Utils.arguments), unquote(Utils.scope), unquote(Utils.mediatype)) do
        var!(conn) = unquote(Utils.conn)
        Mazurka.Resource.Utils.Scope.dump()
        unquote_splicing(events)
        {var!(action), var!(conn)}
      end
    end
  end
end

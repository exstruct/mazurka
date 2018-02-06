defmodule Mazurka.Hyper.Msgpack do
  defmacro __using__(opts) do
    provides =
      opts[:provides] ||
        Macro.escape([
          {"application", "msgpack", %{}},
          {"application", "x-msgpack", %{}},
          {"application", "hyper+x-msgpack", %{}},
          {"application", "hyper+msgpack", %{}}
        ])

    quote do
      @mazurka_mediatypes %Mazurka.Mediatype{
        provides: unquote(provides),
        serializer: unquote(__MODULE__)
      }
    end
  end

  use Mazurka.Serializer
  use Mazurka.Msgpack
end

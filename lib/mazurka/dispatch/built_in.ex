defmodule Mazurka.Dispatch.BuiltIn do
  defmacro __using__(_) do
    quote do
      import Mazurka.Dispatch

      service Rels.self/0, Mazurka.Dispatch.BuiltIn.self(conn)
    end
  end

  def self(conn) do
    self = conn
    |> Mazurka.Resource.Link.from_conn
    |> to_string
    {:ok, self}
  end
end

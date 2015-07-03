defmodule Mazurka.Dispatch.BuiltIn do
  defmacro __using__(_) do
    quote do
      import Mazurka.Dispatch

      service Rels.self/0, Mazurka.Dispatch.BuiltIn.self(conn)
    end
  end

  def self(conn) do
    ## TODO make this pluggable
    # base = Plug.Base.resolve(conn, conn.path_info)
    base = Enum.join(conn.path_info, "/")
    {:ok, "/#{base}#{append_qs(conn)}"}
  end

  defp append_qs(conn) do
    case conn.query_string do
      "" -> ""
      qs ->
        case to_string(qs) do
          "" -> ""
          other -> "?#{other}"
        end
    end
  end
end
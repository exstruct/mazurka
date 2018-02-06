defmodule Mazurka.Resource.Resolve do
  @moduledoc false

  defstruct conn: nil,
            opts: nil,
            body: nil,
            line: nil

  defmacro resolve(do: body) do
    resolve_body(nil, nil, body)
  end

  defmacro resolve(conn, do: body) do
    resolve_body(conn, nil, body)
  end

  defmacro resolve(conn, opts, do: body) do
    resolve_body(conn, opts, body)
  end

  defp resolve_body(conn, opts, body) do
    quote do
      resolve = %unquote(__MODULE__){
        conn: unquote(Macro.escape(conn)),
        opts: unquote(Macro.escape(opts)),
        body: unquote(Macro.escape(body)),
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.put(@mazurka_subject, :value, resolve)
    end
  end
end

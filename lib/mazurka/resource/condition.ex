defmodule Mazurka.Resource.Condition do
  @moduledoc false

  defstruct doc: nil,
            exception: nil,
            conn: nil,
            opts: nil,
            body: nil,
            line: nil

  # TODO add remote/local calls
  defmacro condition(do: body) do
    condition_body(nil, nil, body)
  end

  defmacro condition(conn, do: body) do
    condition_body(conn, nil, body)
  end

  defmacro condition(conn, opts, do: body) do
    condition_body(conn, opts, body)
  end

  defp condition_body(conn, opts, body) do
    quote do
      condition = %unquote(__MODULE__){
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        exception: Mazurka.Builder.get_attribute(__MODULE__, :exception),
        conn: unquote(Macro.escape(conn)),
        opts: unquote(Macro.escape(opts)),
        body: unquote(Macro.escape(body)),
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.append(@mazurka_subject, :conditions, condition)
    end
  end
end

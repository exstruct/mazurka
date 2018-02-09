defmodule Mazurka.Resource.Let do
  @moduledoc false

  defstruct doc: nil,
            body: nil,
            conn: nil,
            opts: nil,
            line: nil

  defmacro let({:=, _, _} = assign) do
    conn = Macro.var(:conn, nil)
    opts = Macro.var(:opts, nil)

    let_body(
      quote do
        _ = unquote(opts)
        unquote(assign)
        unquote(conn)
      end,
      conn,
      opts
    )
  end

  defmacro let(do: body) do
    conn = Macro.var(:conn, nil)
    opts = Macro.var(:opts, nil)

    let_body(
      quote do
        _ = unquote(opts)
        unquote(body)
        unquote(conn)
      end,
      conn,
      opts
    )
  end

  defmacro let(match) when is_tuple(match) do
    conn = Macro.var(:conn, nil)

    let_body(
      quote do
        unquote(match) = unquote(conn)
      end,
      conn,
      nil
    )
  end

  defmacro let(conn, do: body) do
    let_body(body, conn, nil)
  end

  defmacro let(conn, opts, do: body) do
    let_body(body, conn, opts)
  end

  defp let_body(body, conn, opts) do
    quote do
      scope = %unquote(__MODULE__){
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        body: unquote(Macro.escape(body)),
        conn: unquote(Macro.escape(conn)),
        opts: unquote(Macro.escape(opts)),
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.append(@mazurka_subject, :scope, scope)
    end
  end
end

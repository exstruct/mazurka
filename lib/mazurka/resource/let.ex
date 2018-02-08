defmodule Mazurka.Resource.Let do
  @moduledoc false

  defstruct doc: nil,
            lhs: nil,
            rhs: nil,
            conn: nil,
            opts: nil,
            line: nil

  defmacro let({:=, _, [lhs, rhs]}) do
    conn = Macro.var(:conn, nil)
    opts = Macro.var(:opts, nil)
    let_body(lhs, quote do
      _ = unquote(opts)
      {unquote(rhs), unquote(conn)}
    end, conn, opts)
  end

  # TODO
  defmacro let(_args, _body) do
    quote do
    end
  end

  defp let_body(lhs, rhs, conn, opts) do
    quote do
      scope = %unquote(__MODULE__){
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        lhs: unquote(Macro.escape(lhs)),
        rhs: unquote(Macro.escape(rhs)),
        conn: unquote(Macro.escape(conn)),
        opts: unquote(Macro.escape(opts)),
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.append(@mazurka_subject, :scope, scope)
    end
  end
end

defmodule Mazurka.Resource.Let do
  @moduledoc false

  defstruct doc: nil,
            lhs: nil,
            rhs: nil,
            conn: nil,
            opts: nil,
            line: nil

  defmacro let({:=, _, [lhs, rhs]}) do
    let_body(lhs, rhs, nil, nil)
  end

  # TODO
  defmacro let(_args, _body) do
    quote do
    end
  end

  defp let_body(lhs, rhs, conn, opts) do
    quote do
      scope = %unquote(__MODULE__){
        doc: Mazurka.Builder.get_doc(__MODULE__),
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

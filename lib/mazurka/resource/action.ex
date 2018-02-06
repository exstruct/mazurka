defmodule Mazurka.Resource.Action do
  @moduledoc false

  defstruct doc: nil,
            scope: [],
            inputs: nil,
            conn: nil,
            opts: nil,
            body: nil,
            line: nil

  defmacro action(do: body) do
    action_body(nil, nil, nil, body)
  end

  defmacro action(inputs, do: body) do
    action_body(inputs, nil, nil, body)
  end

  defmacro action(inputs, conn, do: body) do
    action_body(inputs, conn, nil, body)
  end

  defmacro action(inputs, conn, opts, do: body) do
    action_body(inputs, conn, opts, body)
  end

  defp action_body(inputs, conn, opts, body) do
    quote do
      action = %unquote(__MODULE__){
        doc: Mazurka.Builder.get_doc(__MODULE__),
        inputs: unquote(Macro.escape(inputs)),
        conn: unquote(Macro.escape(conn)),
        opts: unquote(Macro.escape(opts)),
        body: unquote(Macro.escape(body)),
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.put(@mazurka_subject, :action, action)
    end
  end
end

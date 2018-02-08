defmodule Mazurka.Resource.Validate do
  @moduledoc false

  defstruct doc: nil,
            conn: nil,
            opts: nil,
            body: nil,
            value: nil,
            line: nil

  defmacro validate({:/, meta, [call, 1]}) do
    value = Macro.var(:value, nil)
    body = {call, meta, [value]}
    validate_body(value, nil, nil, body)
  end

  defmacro validate({:/, meta, [call, 2]}) do
    value = Macro.var(:value, nil)
    conn = Macro.var(:conn, nil)
    body = {call, meta, [value, conn]}
    validate_body(value, conn, nil, body)
  end

  defmacro validate({:/, meta, [call, 3]}) do
    value = Macro.var(:value, nil)
    conn = Macro.var(:conn, nil)
    opts = Macro.var(:opts, nil)
    body = {call, meta, [value, conn, opts]}
    validate_body(value, conn, opts, body)
  end

  defmacro validate(do: body) do
    validate_body(Macro.var(:_, nil), nil, nil, body)
  end

  defmacro validate(value, do: body) do
    validate_body(value, nil, nil, body)
  end

  defmacro validate(value, conn, do: body) do
    validate_body(value, conn, nil, body)
  end

  defmacro validate(value, conn, opts, do: body) do
    validate_body(value, conn, opts, body)
  end

  defp validate_body(value, conn, opts, body) do
    quote do
      validation = %unquote(__MODULE__){
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        conn: unquote(Macro.escape(conn)),
        opts: unquote(Macro.escape(opts)),
        body: unquote(Macro.escape(body)),
        value: unquote(Macro.escape(value)),
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.append(@mazurka_subject, :validations, validation)
    end
  end
end

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

      @mazurka_subject Mazurka.Builder.append(@mazurka_subject, :value, resolve)
    end
  end

  alias Mazurka.Compiler

  defimpl Compiler.Serializable do
    def compile(
          %{
            conn: nil,
            opts: nil,
            line: line
          } = resolve,
          vars,
          impl
        ) do
      {enter, vars} = impl.enter(resolve, vars)
      {exit, vars} = impl.exit(resolve, vars)

      {Compiler.join(
         [
           enter,
           exit
         ],
         line
       ), vars}
    end

    def compile(
          %{
            conn: conn,
            opts: opts,
            body: body,
            line: line
          } = resolve,
          %{conn: v_conn, opts: v_opts} = vars,
          impl
        ) do
      value = Macro.var(:value, __MODULE__)
      resolve = %{resolve | body: value}
      {enter, vars} = impl.enter(resolve, vars)
      {exit, vars} = impl.exit(resolve, vars)

      {Compiler.join(
         [
           quote do
             unquote(conn) = unquote(v_conn)
             unquote(opts || Macro.var(:_, nil)) = unquote(v_opts)
             {unquote(value), unquote(v_conn)} = unquote(body)
           end,
           enter,
           exit
         ],
         line
       ), vars}
    end
  end

  defimpl Compiler.Compilable do
    def compile(
          %{
            conn: nil,
            opts: nil,
            body: body
          },
          vars,
          _
        ) do
      {body, vars}
    end

    def compile(
          %{
            conn: conn,
            opts: opts,
            body: body,
            line: line
          },
          %{conn: v_conn, opts: v_opts} = vars,
          _
        ) do
      value = Macro.var(:value, __MODULE__)

      {quote line: line do
         unquote(conn || Macro.var(:_, nil)) = unquote(v_conn)
         unquote(opts || Macro.var(:_, nil)) = unquote(v_opts)
         {unquote(value), unquote(v_conn)} = unquote(body)
         unquote(value)
       end, vars}
    end
  end

  defimpl Mazurka.Serializer.JSON do
    def enter(%{body: body, line: line}, vars, _impl) do
      %{buffer: buffer} = vars

      {quote line: line do
         unquote(buffer) = [
           Poison.Encoder.encode(unquote(body), %{})
           | unquote(buffer)
         ]
       end, vars}
    end

    def exit(_, vars, _impl) do
      {nil, vars}
    end
  end

  defimpl Mazurka.Serializer.Msgpack do
    def enter(%{body: body, line: line}, vars, _impl) do
      %{buffer: buffer} = vars

      {quote line: line do
         unquote(buffer) = [
           Msgpax.Packer.pack(unquote(body))
           | unquote(buffer)
         ]
       end, vars}
    end

    def exit(_, vars, _impl) do
      {nil, vars}
    end
  end
end

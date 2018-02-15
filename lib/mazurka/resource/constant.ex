defmodule Mazurka.Resource.Constant do
  @moduledoc false

  defstruct value: nil,
            line: nil

  defmacro constant([{:do, value} | _]) do
    constant_body(value)
  end

  defmacro constant(value) do
    constant_body(value)
  end

  defp constant_body(value) do
    quote do
      constant = %unquote(__MODULE__){
        value: unquote(value),
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.append(@mazurka_subject, :value, constant)
    end
  end

  alias Mazurka.Compiler

  defimpl Compiler.Serializable do
    def compile(
          %@for{line: line} = constant,
          vars,
          impl
        ) do
      {enter, vars} = impl.enter(constant, vars)
      {exit, vars} = impl.exit(constant, vars)

      {Compiler.join(
         [
           enter,
           exit
         ],
         line
       ), vars}
    end
  end

  defimpl Mazurka.Serializer.JSON do
    def enter(%{value: value, line: line}, vars, _impl) do
      %{buffer: buffer} = vars

      {quote line: line do
         unquote(buffer) = [
           unquote(Poison.encode!(value))
           | unquote(buffer)
         ]
       end, vars}
    end

    def exit(_, vars, _impl) do
      {nil, vars}
    end
  end

  defimpl Mazurka.Serializer.Msgpack do
    def enter(%{value: value, line: line}, vars, _impl) do
      %{buffer: buffer} = vars

      {quote line: line do
         unquote(buffer) = [
           unquote(pack(value))
           | unquote(buffer)
         ]
       end, vars}
    end

    def exit(_, vars, _impl) do
      {nil, vars}
    end

    defp pack(value) do
      value
      |> Msgpax.Packer.pack()
      |> :erlang.iolist_to_binary()
    end
  end
end

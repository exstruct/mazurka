defmodule Mazurka.Resource.Field do
  @moduledoc false

  defstruct conditions: [],
            doc: nil,
            name: nil,
            scope: [],
            value: [],
            line: nil

  defmacro field(name, do: block) do
    quote do
      prev = @mazurka_subject

      @mazurka_subject %unquote(__MODULE__){
        name: unquote(name),
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        line: __ENV__.line
      }

      import Mazurka.Resource.{AffordanceFor, Collection, Condition, Constant, Map, Resolve}
      unquote(block)

      %{conditions: conditions} = field = @mazurka_subject

      field = %{
        field
        | conditions: :lists.reverse(conditions)
      }

      @mazurka_subject Mazurka.Builder.append(prev, :fields, field)
    end
  end

  alias Mazurka.Compiler

  defimpl Compiler.Serializable do
    def compile(
          %{
            conditions: conditions,
            scope: scope,
            value: value,
            line: line
          } = field,
          vars,
          impl
        ) do
      {enter, vars} = impl.enter(field, vars)
      {body, vars} = @protocol.compile(value, vars, impl)

      args =
        vars
        |> Map.drop([:buffer, :conn, :opts])
        |> Map.values()
        |> Enum.map(fn
          [var | _] when is_tuple(var) ->
            var

          var when is_tuple(var) ->
            var
        end)

      {exit, vars} = impl.exit(field, vars)

      body = Compiler.join([enter, body, exit], line)
      {body, vars} = Compiler.wrap_conditions(body, vars, conditions, nil, args)
      {body, vars} = Compiler.wrap_scope(body, vars, scope)
      {body, vars}
    end
  end

  defimpl Mazurka.Serializer.JSON do
    def enter(_, vars, _impl) do
      %{map_suffix: [map_suffix | _], buffer: buffer} = vars

      {quote do
         unquote(buffer) = [unquote(map_suffix) | unquote(buffer)]
       end, vars}
    end

    def exit(%{name: name}, vars, _impl) do
      %{map_suffix: [map_suffix | _], buffer: buffer} = vars

      {quote do
         unquote(buffer) = [
           unquote(Poison.encode!(name) <> ":") | unquote(buffer)
         ]

         unquote(map_suffix) = ","
       end, vars}
    end
  end

  defimpl Mazurka.Serializer.Msgpack do
    def enter(_, vars, _impl) do
      {nil, vars}
    end

    def exit(%{name: name}, vars, _impl) do
      %{map_size: [map_size | _], buffer: buffer} = vars

      {quote do
         unquote(buffer) = [
           unquote(pack(name)) | unquote(buffer)
         ]

         unquote(map_size) = unquote(map_size) + 1
       end, vars}
    end

    defp pack(value) do
      value
      |> Msgpax.Packer.pack()
      |> :erlang.iolist_to_binary()
    end
  end
end

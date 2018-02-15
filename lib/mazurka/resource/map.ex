defmodule Mazurka.Resource.Map do
  @moduledoc false

  defstruct conditions: [],
            doc: nil,
            fields: [],
            scope: [],
            line: nil

  defmacro map(do: block) do
    quote do
      prev = @mazurka_subject

      @mazurka_subject %unquote(__MODULE__){
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        line: __ENV__.line
      }

      import Mazurka.Resource.{Condition, Field}
      unquote(block)
      # import Mazurka.Resource.{Condition, Field}, only: []

      %{conditions: conditions, fields: fields} = map = @mazurka_subject

      map = %{
        map
        | fields: :lists.reverse(fields),
          conditions: :lists.reverse(conditions)
      }

      @mazurka_subject Mazurka.Builder.append(prev, :value, map)
    end
  end

  alias Mazurka.Compiler

  defimpl Compiler.Serializable do
    def compile(
          %{
            conditions: conditions,
            scope: scope,
            fields: fields,
            line: line
          } = map,
          vars,
          impl
        ) do
      {enter, vars} = impl.enter(map, vars)
      {body, vars} = Enum.map_reduce(fields, vars, &@protocol.compile(&1, &2, impl))
      body = :lists.reverse(body)
      {exit, vars} = impl.exit(map, vars)

      {body, vars} = Compiler.wrap_conditions(body, vars, conditions)
      {body, vars} = Compiler.wrap_scope(body, vars, scope)

      {Compiler.join(
         [
           enter,
           body,
           exit
         ],
         line
       ), vars}
    end
  end

  defimpl Mazurka.Serializer.JSON do
    def enter(_, vars, _) do
      %{map_suffix: [map_suffix | _]} =
        vars =
        Map.update(vars, :map_suffix, [suffix_var(0)], fn suffixes ->
          [suffix_var(length(suffixes)) | suffixes]
        end)

      %{buffer: buffer} = vars

      {quote do
         unquote(map_suffix) = []
         unquote(buffer) = ["}" | unquote(buffer)]
       end, vars}
    end

    def exit(_, vars, _) do
      %{buffer: buffer, map_suffix: [suffix | map_suffix]} = vars

      {quote do
         _ = unquote(suffix)
         unquote(buffer) = ["{" | unquote(buffer)]
       end, %{vars | map_suffix: map_suffix}}
    end

    defp suffix_var(id) do
      Macro.var(:"map_suffix_#{id}", __MODULE__)
    end
  end

  defimpl Mazurka.Serializer.Msgpack do
    def enter(_, vars, _) do
      %{map_size: [map_size | _]} =
        vars =
        Map.update(vars, :map_size, [map_size_var(0)], fn sizes ->
          [map_size_var(length(sizes)) | sizes]
        end)

      {quote do
         unquote(map_size) = 0
       end, vars}
    end

    def exit(_, vars, _) do
      %{buffer: buffer, map_size: [map_size | map_sizes]} = vars

      {quote do
         unquote(buffer) = [
           case unquote(map_size) do
             s when s < 16 -> <<0b10000000 + s::8>>
             s when s < 0x10000 -> <<0xDE, s::16>>
             s when s < 0x100000000 -> <<0xDF, s::32>>
           end
           | unquote(buffer)
         ]
       end, %{vars | map_size: map_sizes}}
    end

    defp map_size_var(id) do
      Macro.var(:"map_size_#{id}", __MODULE__)
    end
  end
end

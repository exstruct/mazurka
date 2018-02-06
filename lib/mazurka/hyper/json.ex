defmodule Mazurka.Hyper.JSON do
  defmacro __using__(opts) do
    provides =
      opts[:provides] ||
        Macro.escape([
          {"application", "json", %{}},
          {"application", "hyper+json", %{}}
        ])

    quote do
      @mazurka_mediatypes %Mazurka.Mediatype{
        provides: unquote(provides),
        serializer: unquote(__MODULE__)
      }
    end
  end

  use Mazurka.Serializer
  use Mazurka.JSON
end

# defmodule Mazurka.Hyper.JSON.Util do
#   @moduledoc false

#   def format_conditions(conditions, vars) do
#     {conditions_ast, vars} = Enum.map_reduce(conditions, vars, &Mazurka.Hyper.JSON.serialize/2)

#     conditions_ast =
#       Enum.reduce(conditions_ast, true, fn
#         condition, true ->
#           condition

#         condition, acc ->
#           {:&&, [], [condition, acc]}
#       end)

#     {conditions_ast, vars}
#   end

#   def optimize_ast({:__block__, info, statements}) do
#     acc = optimize_statement(statements, [])
#     {:__block__, info, :lists.reverse(acc)}
#   end

#   defp optimize_statement([], acc) do
#     acc
#   end

#   defp optimize_statement([{:__block__, _, statements} | rest], acc) do
#     acc = optimize_statement(statements, acc)
#     optimize_statement(rest, acc)
#   end

#   defp optimize_statement(
#          [
#            {:=, a_meta, [{:buffer, _, _} = var, buffer]},
#            {:=, _, [{:buffer, _, _}, items]}
#            | rest
#          ],
#          acc
#        ) do
#     statement = {
#       :=,
#       a_meta,
#       [var, optimize_cons(items, buffer, [])]
#     }

#     optimize_statement([statement | rest], acc)
#   end

#   defp optimize_statement([{:=, meta, [lhs, rhs]} | rest], acc) do
#     [rhs] = optimize_statement([rhs], [])
#     acc = [{:=, meta, [lhs, rhs]} | acc]
#     optimize_statement(rest, acc)
#   end

#   defp optimize_statement([{:case, meta, [subject, [do: clauses]]} | rest], acc) do
#     clauses = optimize_statement(clauses, []) |> :lists.reverse()
#     acc = [{:case, meta, [subject, [do: clauses]]} | acc]
#     optimize_statement(rest, acc)
#   end

#   defp optimize_statement([{:->, meta, [clause, body]} | rest], acc) do
#     body =
#       case optimize_statement([body], []) do
#         [b] -> b
#         b -> {:__block__, [], :lists.reverse(b)}
#       end

#     acc = [{:->, meta, [clause, body]} | acc]
#     optimize_statement(rest, acc)
#   end

#   defp optimize_statement([statement | rest], acc) do
#     acc = [statement | acc]
#     optimize_statement(rest, acc)
#   end

#   defp optimize_cons([], [], acc) do
#     optimize_cons_binary(acc, [])
#   end

#   defp optimize_cons([{:|, _, [item, {:buffer, _, _}]}], buffer, acc) when length(buffer) > 0 do
#     acc = [item | acc]
#     optimize_cons(buffer, [], acc)
#   end

#   defp optimize_cons([item | rest], buffer, acc) do
#     acc = [item | acc]
#     optimize_cons(rest, buffer, acc)
#   end

#   defp optimize_cons_binary([], acc) do
#     acc
#   end

#   defp optimize_cons_binary([a, b | rest], acc) when is_binary(a) and is_binary(b) do
#     optimize_cons_binary([b <> a | rest], acc)
#   end

#   defp optimize_cons_binary([a | rest], acc) do
#     optimize_cons_binary(rest, [a | acc])
#   end
# end

# defimpl Mazurka.Hyper.JSON, for: Mazurka.Resource.Action do
#   def serialize(
#         %{
#           conditions: conditions,
#           scope: scope,
#           inputs: inputs,
#           value: %{line: line}
#         },
#         %{conn: conn} = vars
#       ) do
#     buffer = Macro.var(:buffer, __MODULE__)
#     vars = Map.put(vars, :buffer, buffer)

#     {body, vars} =
#       @protocol.serialize(
#         %Mazurka.Resource.Map{
#           conditions: conditions,
#           scope: scope,
#           fields: [
#             %Mazurka.Resource.Field{
#               name: "action",
#               value: %Mazurka.Resource.Constant{
#                 value: "http://example.com"
#               }
#             },
#             %Mazurka.Resource.Field{
#               name: "method",
#               value: %Mazurka.Resource.Constant{
#                 value: "POST"
#               }
#             },
#             %Mazurka.Resource.Field{
#               name: "input",
#               value: %Mazurka.Resource.Map{
#                 line: line,
#                 fields: inputs
#               }
#             }
#           ],
#           line: line
#         },
#         vars
#       )

#     {quote do
#        unquote(buffer) = []
#        unquote(body)
#        {unquote(buffer), unquote(conn)}
#      end, vars}
#   end
# end

# defimpl Mazurka.Hyper.JSON, for: Mazurka.Resource do
#   def serialize(
#         %{conditions: [], scope: _scope, value: value},
#         %{conn: conn} = vars
#       ) do
#     # TODO compile scope
#     buffer = Macro.var(:buffer, __MODULE__)
#     vars = Map.put(vars, :buffer, buffer)
#     {body, vars} = @protocol.serialize(value, vars)

#     {quote do
#        unquote(buffer) = []
#        unquote(body)
#        {unquote(buffer), unquote(conn)}
#      end, vars}
#   end
# end

# defimpl Mazurka.Hyper.JSON, for: Mazurka.Resource.Map do
#   def serialize(
#         %{conditions: [], fields: fields, line: line},
#         %{buffer: buffer} = vars
#       ) do
#     %{map_suffix: [map_suffix | _]} =
#       vars =
#       Map.update(vars, :map_suffix, [suffix_var(0)], fn suffixes ->
#         [suffix_var(length(suffixes)) | suffixes]
#       end)

#     {fields_ast, vars} = Enum.map_reduce(fields, vars, &@protocol.serialize/2)

#     ast =
#       quote line: line do
#         unquote(map_suffix) = []
#         unquote(buffer) = ["}" | unquote(buffer)]

#         unquote_splicing(:lists.reverse(fields_ast))

#         _ = unquote(map_suffix)
#         unquote(buffer) = ["{" | unquote(buffer)]
#       end

#     vars = Map.update!(vars, :map_suffix, &tl/1)

#     {ast, vars}
#   end

#   def serialize(
#         %{conditions: conditions, line: line} = map,
#         %{buffer: buffer, conn: conn} = vars
#       ) do
#     {conditions_ast, vars} = @protocol.Util.format_conditions(conditions, vars)
#     {map_ast, vars} = serialize(%{map | conditions: []}, vars)

#     ast =
#       quote line: line do
#         {unquote(buffer), unquote(conn)} =
#           case unquote(conditions_ast) do
#             res when res === nil or res === false ->
#               {unquote(buffer), unquote(conn)}

#             _ ->
#               unquote(map_ast)
#               {unquote(buffer), unquote(conn)}
#           end
#       end

#     {ast, vars}
#   end

#   def suffix_var(id) do
#     Macro.var(:"map_suffix_#{id}", __MODULE__)
#   end
# end

# defimpl Mazurka.Hyper.JSON, for: Mazurka.Resource.Field do
#   def serialize(
#         %{conditions: [], name: name, value: value, line: line},
#         %{buffer: buffer, map_suffix: [map_suffix | _]} = vars
#       ) do
#     {value_ast, vars} = @protocol.serialize(value, vars)

#     ast =
#       quote line: line do
#         unquote(buffer) = [unquote(map_suffix) | unquote(buffer)]
#         unquote(value_ast)

#         unquote(buffer) = [
#           unquote(Poison.encode!(name) <> ":") | unquote(buffer)
#         ]

#         unquote(map_suffix) = ","
#       end

#     {ast, vars}
#   end

#   def serialize(
#         %{conditions: conditions, line: line} = field,
#         %{buffer: buffer, conn: conn, map_suffix: [map_suffix | _]} = vars
#       ) do
#     {conditions_ast, vars} = @protocol.Util.format_conditions(conditions, vars)
#     {field_ast, vars} = serialize(%{field | conditions: []}, vars)

#     ast =
#       quote line: line do
#         {unquote(buffer), unquote(conn), unquote(map_suffix)} =
#           case unquote(conditions_ast) do
#             res when res === nil or res === false ->
#               {unquote(buffer), unquote(conn), unquote(map_suffix)}

#             _ ->
#               unquote(field_ast)
#               {unquote(buffer), unquote(conn), unquote(map_suffix)}
#           end
#       end

#     {ast, vars}
#   end
# end

# defimpl Mazurka.Hyper.JSON, for: Mazurka.Resource.Resolve do
#   def serialize(
#         %{conn: nil, opts: nil, body: body, line: line},
#         %{buffer: buffer} = vars
#       ) do
#     ast =
#       quote line: line do
#         unquote(buffer) = [
#           Poison.Encoder.encode(unquote(body), %{})
#           | unquote(buffer)
#         ]
#       end

#     {ast, vars}
#   end

#   def serialize(
#         %{conn: conn, opts: opts, body: body, line: line},
#         %{buffer: buffer, conn: v_conn, opts: v_opts} = vars
#       ) do
#     ast =
#       quote line: line do
#         unquote(conn) = unquote(v_conn)
#         unquote(opts || Macro.var(:_, nil)) = unquote(v_opts)
#         {value, unquote(v_conn)} = unquote(body)

#         unquote(buffer) = [
#           Poison.Encoder.encode(value, %{})
#           | unquote(buffer)
#         ]
#       end

#     {ast, vars}
#   end
# end

# defimpl Mazurka.Hyper.JSON, for: Mazurka.Resource.Condition do
#   def serialize(
#         %{conn: nil, opts: nil, body: body},
#         vars
#       ) do
#     {body, vars}
#   end

#   def serialize(
#         %{conn: conn, opts: opts, body: body, line: line},
#         %{conn: v_conn, opts: v_opts} = vars
#       ) do
#     ast =
#       quote line: line do
#         unquote(conn) = unquote(v_conn)
#         unquote(opts || Macro.var(:_, nil)) = unquote(v_opts)
#         unquote(body)
#       end

#     {ast, vars}
#   end
# end

# defimpl Mazurka.Hyper.JSON, for: Mazurka.Resource.Constant do
#   def serialize(
#         %{value: value, line: line},
#         %{buffer: buffer} = vars
#       ) do
#     ast =
#       quote line: line do
#         unquote(buffer) = [
#           unquote(Poison.encode!(value))
#           | unquote(buffer)
#         ]
#       end

#     {ast, vars}
#   end
# end

# defimpl Mazurka.Hyper.JSON, for: Mazurka.Resource.Input do
#   def serialize(
#         %{
#           conditions: conditions,
#           info: info,
#           name: name,
#           scope: scope,
#           value: value,
#           line: line
#         },
#         vars
#       ) do
#     fields = Map.put(info, :value, value)

#     %Mazurka.Resource.Field{
#       conditions: conditions,
#       name: name,
#       scope: scope,
#       value: %Mazurka.Resource.Map{
#         line: line,
#         fields:
#           for field <- fields, {name, value} = field do
#             %Mazurka.Resource.Field{
#               name: name,
#               value: value,
#               line: line
#             }
#           end
#       },
#       line: line
#     }
#     |> @protocol.serialize(vars)
#   end
# end

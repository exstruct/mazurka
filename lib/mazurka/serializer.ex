defmodule Mazurka.Serializer do
  defmacro __using__(_) do
    quote do
      def action(resource, vars) do
        Mazurka.Serializer.action(resource, vars, __MODULE__)
      end

      def affordance(resource, vars) do
        Mazurka.Serializer.affordance(resource, vars, __MODULE__)
      end
    end
  end

  alias Mazurka.Resource

  def action(
        %Resource{conditions: conditions, scope: scope, value: value},
        vars,
        impl
      ) do
    buffer = Macro.var(:buffer, __MODULE__)
    vars = Map.put(vars, :buffer, buffer)
    # TODO action callback
    {body, vars} = compile(value, vars, impl)
    {body, vars} = wrap_scope(body, vars, scope)
    {body, vars} = wrap_conditions(body, vars, conditions, Mazurka.ConditionError)

    body =
      join([
        quote(do: unquote(buffer) = []),
        body,
        quote(do: {unquote(vars.buffer), unquote(vars.conn)})
      ])

    body |> Macro.to_string() |> IO.puts()

    body
  end

  def affordance(
        %Resource{conditions: conditions, scope: scope, value: value},
        vars,
        impl
      ) do
    buffer = Macro.var(:buffer, __MODULE__)
    vars = Map.put(vars, :buffer, buffer)
    # TODO affordance callback
    {body, vars} = compile(value, vars, impl)
    {body, vars} = wrap_scope(body, vars, scope)
    {body, vars} = wrap_conditions(body, vars, conditions)

    join([
      quote(do: unquote(buffer) = []),
      body,
      quote(do: {unquote(vars.buffer), unquote(vars.conn)})
    ])
  end

  defp wrap_scope(ast, vars, []) do
    {ast, vars}
  end

  defp wrap_scope(ast, vars, _) do
    # TODO
    {ast, vars}
  end

  defp wrap_conditions(
         ast,
         vars,
         conditions,
         invariant \\ nil,
         args \\ []
       )

  defp wrap_conditions(ast, vars, [], _, _) do
    {ast, vars}
  end

  defp wrap_conditions(
         ast,
         %{buffer: buffer, conn: conn} = vars,
         conditions,
         invariant,
         args
       ) do
    {conditions_ast, vars} = compile_conditions(conditions, vars, invariant)

    {quote do
       {unquote(buffer), unquote(conn), unquote_splicing(args)} =
         case unquote(conditions_ast) do
           res when res === nil or res === false ->
             {unquote(buffer), unquote(conn), unquote_splicing(args)}

           _ ->
             unquote(ast)
             {unquote(buffer), unquote(conn), unquote_splicing(args)}
         end
     end, vars}
  end

  defp compile_conditions(conditions, vars, invariant) do
    {conditions_ast, vars} =
      Enum.map_reduce(conditions, vars, &compile_condition(&1, &2, invariant))

    conditions_ast =
      Enum.reduce(conditions_ast, true, fn
        condition, true ->
          condition

        condition, acc ->
          {:&&, [], [condition, acc]}
      end)

    {conditions_ast, vars}
  end

  defp compile_condition(%{doc: doc, line: line} = condition, vars, invariant)
       when not is_nil(invariant) do
    {ast, vars} = compile_condition(condition, vars, nil)

    {quote line: line do
       unquote(ast) || raise(unquote(invariant), message: unquote(doc))
     end, vars}
  end

  defp compile_condition(
         %{conn: nil, opts: nil, body: body},
         vars,
         _
       ) do
    {body, vars}
  end

  defp compile_condition(
         %{conn: conn, opts: opts, body: body, line: line},
         %{conn: v_conn, opts: v_opts} = vars,
         _
       ) do
    {join(
       [
         quote do
           unquote(conn) = unquote(v_conn)
           unquote(opts || Macro.var(:_, nil)) = unquote(v_opts)
         end,
         body
       ],
       line
     ), vars}
  end

  defp compile(
         %Resource.Map{conditions: conditions, scope: scope, fields: fields, line: line} = map,
         vars,
         impl
       ) do
    {enter, vars} = impl.enter(map, vars)
    {body, vars} = Enum.map_reduce(fields, vars, &compile(&1, &2, impl))
    body = :lists.reverse(body)
    {exit, vars} = impl.exit(map, vars)

    {body, vars} = wrap_scope(body, vars, scope)
    {body, vars} = wrap_conditions(body, vars, conditions)

    {join(
       [
         enter,
         body,
         exit
       ],
       line
     ), vars}
  end

  defp compile(
         %Resource.Field{conditions: conditions, scope: scope, value: value, line: line} = field,
         vars,
         impl
       ) do
    {enter, vars} = impl.enter(field, vars)
    {body, vars} = compile(value, vars, impl)
    {exit, vars} = impl.exit(field, vars)

    {body, vars} = wrap_scope(body, vars, scope)
    {body, vars} = wrap_conditions(body, vars, conditions)

    {join(
       [
         enter,
         body,
         exit
       ],
       line
     ), vars}
  end

  defp compile(
         %Resource.Resolve{conn: nil, opts: nil, line: line} = resolve,
         vars,
         impl
       ) do
    {enter, vars} = impl.enter(resolve, vars)
    {exit, vars} = impl.exit(resolve, vars)

    {join(
       [
         enter,
         exit
       ],
       line
     ), vars}
  end

  defp compile(
         %Resource.Resolve{conn: conn, opts: opts, body: body, line: line} = resolve,
         %{buffer: buffer, conn: v_conn, opts: v_opts} = vars,
         impl
       ) do
    value = Macro.var(:value, __MODULE__)
    resolve = %{resolve | body: value}
    {enter, vars} = impl.enter(resolve, vars)
    {exit, vars} = impl.exit(resolve, vars)

    {join(
       [
         quote do
           unquote(conn) = unquote(v_conn)
           unquote(opts || Macro.var(:_, nil)) = unquote(v_opts)
           {unquote(value), unquote(v_conn)} = unquote(body)
         end,
         enter,
         exit,
       ],
       line
     ), vars}
  end

  defp compile(
         %Resource.Constant{line: line} = constant,
         vars,
         impl
       ) do
    {enter, vars} = impl.enter(constant, vars)
    {exit, vars} = impl.exit(constant, vars)

    {join(
       [
         enter,
         exit
       ],
       line
     ), vars}
  end

  defp compile(struct, vars, _) do
    # TODO throw an error if unimplemented
    IO.inspect(struct)
    {nil, vars}
  end

  defp join(items, line \\ 1) do
    {:__block__, [line: line], items |> join_r |> Enum.to_list()}
  end

  defp join_r(items) do
    items
    |> Stream.flat_map(fn
      {:__block__, _, items} ->
        join_r(items)

      nil ->
        []

      [] ->
        []

      items when is_list(items) ->
        join_r(items)

      item ->
        [item]
    end)
  end
end
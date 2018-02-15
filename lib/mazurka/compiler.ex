defmodule Mazurka.Compiler do
  @moduledoc false

  defstruct doc: nil,
            lhs: nil,
            rhs: nil,
            conn: nil,
            opts: nil,
            line: nil

  defmacro __using__(_) do
    quote do
      @doc false
      def action(resource, vars) do
        Mazurka.Compiler.action(resource, vars, __MODULE__)
      end

      @doc false
      def affordance(resource, vars) do
        Mazurka.Compiler.affordance(resource, vars, __MODULE__)
      end
    end
  end

  alias Mazurka.Resource

  def action(
        %Resource{
          conditions: conditions,
          scope: scope,
          value: value
        },
        vars,
        impl
      ) do
    buffer = Macro.var(:buffer, __MODULE__)
    vars = Map.put(vars, :buffer, buffer)
    # TODO action callback
    {body, vars} = __MODULE__.Serializable.compile(value, vars, impl)
    {body, vars} = wrap_conditions(body, vars, conditions, Mazurka.ConditionError)
    {body, vars} = wrap_scope(body, vars, scope)

    body =
      join([
        quote(do: unquote(buffer) = []),
        body,
        quote(do: {unquote(vars.buffer), unquote(vars.conn)})
      ])

    # body |> Macro.to_string() |> IO.puts()

    body
  end

  def affordance(
        %Resource{
          conditions: conditions,
          scope: scope,
          value: value
        },
        vars,
        impl
      ) do
    buffer = Macro.var(:buffer, __MODULE__)
    vars = Map.put(vars, :buffer, buffer)
    # TODO affordance callback
    {body, vars} = __MODULE__.Serializable.compile(value, vars, impl)
    {body, vars} = wrap_conditions(body, vars, conditions)
    {body, vars} = wrap_scope(body, vars, scope)

    join([
      quote(do: unquote(buffer) = []),
      body,
      quote(do: {unquote(vars.buffer), unquote(vars.conn)})
    ])
  end

  def wrap_scope(ast, vars, []) do
    {ast, vars}
  end

  def wrap_scope(ast, vars, assigns) do
    {scope, vars} = __MODULE__.Scopable.compile(assigns, vars)

    {assigns, vars} = Enum.map_reduce(assigns, vars, &__MODULE__.Compilable.compile/2)

    {join([
       scope,
       assigns,
       ast
     ]), vars}
  end

  def wrap_conditions(
        ast,
        vars,
        conditions,
        invariant \\ nil,
        args \\ []
      )

  def wrap_conditions(ast, vars, [], _, _) do
    {ast, vars}
  end

  def wrap_conditions(
        ast,
        %{buffer: buffer, conn: conn} = vars,
        conditions,
        nil,
        args
      ) do
    {conditions_ast, vars} = compile_conditions(conditions, vars, nil)

    {quote do
       {unquote(buffer), unquote(conn), unquote_splicing(args)} =
         case unquote(conditions_ast) do
           res when res === nil or res === false ->
             {unquote(buffer), unquote(conn), unquote_splicing(args)}

           _ ->
             unquote(
               join([
                 ast,
                 quote do
                   {unquote(buffer), unquote(conn), unquote_splicing(args)}
                 end
               ])
             )
         end
     end, vars}
  end

  def wrap_conditions(
        ast,
        vars,
        conditions,
        invariant,
        _args
      ) do
    {conditions_ast, vars} = compile_conditions(conditions, vars, invariant)

    {quote do
       unquote(conditions_ast)
       unquote(ast)
     end, vars}
  end

  defp compile_conditions(conditions, vars, invariant) do
    {conditions_ast, vars} =
      Enum.map_reduce(conditions, vars, &__MODULE__.Compilable.compile(&1, &2, invariant))

    conditions_ast =
      Enum.reduce(conditions_ast, true, fn
        condition, true ->
          condition

        condition, acc ->
          {:&&, [], [condition, acc]}
      end)

    {conditions_ast, vars}
  end

  def join(items, line \\ 1) do
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

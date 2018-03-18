defmodule Mazurka.Resource.Condition do
  @moduledoc false

  defmacro __using__(_) do
    Module.register_attribute(__CALLER__.module, :mazurka_conditions, accumulate: true)

    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro condition(impl) do
    condition_body(nil, [], impl, __CALLER__)
  end

  defmacro condition(opts, impl) when is_list(opts) do
    condition_body(nil, opts, impl, __CALLER__)
  end

  defmacro condition(conn, impl) do
    condition_body(conn, [], impl, __CALLER__)
  end

  defmacro condition(conn, opts, impl) do
    condition_body(conn, opts, impl, __CALLER__)
  end

  defp condition_body(conn, opts, impl, env) do
    doc = opts[:message] || "Condition failure"
    {exception, error} = extract_exception(opts[:raise], doc)

    {exception, _} = Code.eval_quoted(exception, [], env)
    # TODO only set if available
    %{module: module} = env
    Module.put_attribute(module, :mazurka_conditions, {doc, exception})

    v_conn = Macro.var(:conn, __MODULE__)

    body = compile_impl(v_conn, error, impl)

    quote generated: true do
      unquote(v_conn) = unquote(conn || Macro.var(:conn, nil))
      unquote(body)
    end
    |> maybe_assign(conn)
  end

  defp compile_impl(conn, error, {:&, _, [{:/, meta, [{call, _, _}, arity]}]}) do
    case arity do
      1 ->
        body = {call, meta, [conn]}
        compile_impl(conn, error, do: body)
    end
  end

  defp compile_impl(conn, error, {:&, _, _} = fun) do
    body = {{:., [], [fun]}, [], [conn]}
    compile_impl(conn, error, do: body)
  end

  defp compile_impl(conn, error, {:fn, _, clauses}) do
    body =
      quote do
        case var!(conn, nil), do: unquote(clauses)
      end

    compile_impl(conn, error, do: body)
  end

  defp compile_impl(conn, error, do: body) do
    quote generated: true do
      var!(conn, nil) = unquote(conn)

      case {unquote(body), var!(conn, nil)} do
        {res, %{private: %{mazurka_affordance: true}} = conn} when res === false or res === nil ->
          raise Mazurka.AffordanceConditionError, conn: conn, error: unquote(error)

        {res, _} when res === false or res === nil ->
          raise unquote(error)

        {true, conn} ->
          conn

        {term, _conn} ->
          raise %BadBooleanError{operator: :condition, term: term}
      end
    end
  end

  defp extract_exception({:%, _, [struct, _fields]} = ast, _) do
    {struct, ast}
  end

  defp extract_exception(nil, message) do
    {Mazurka.ConditionError,
     quote do
       %Mazurka.ConditionError{message: unquote(message)}
     end}
  end

  defp extract_exception({:__aliases__, _, _} = exception, message) do
    {exception,
     quote do
       %unquote(exception){message: unquote(message)}
     end}
  end

  defp maybe_assign(body, nil) do
    quote do
      unquote(Macro.var(:conn, nil)) = unquote(body)
    end
  end

  defp maybe_assign(body, _) do
    body
  end
end

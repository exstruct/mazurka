defmodule Mazurka.Resource.Test do
  require Logger

  defmacro __using__(_) do
    Mazurka.Resource.Test.Case.init(__CALLER__)
    quote do
      import unquote(__MODULE__), only: [test: 2]
    end
  end

  defmacro test(name, [do: block, after: assertions]) do
    block = Macro.escape(block)
    assertions = Macro.escape(assertions)

    quote do
      tags = Mazurka.Resource.Test.Case.get_tags(__ENV__)
      data = {unquote(name), unquote(block), unquote(assertions), tags}
      Mazurka.Compiler.Utils.put(__ENV__, nil, unquote(__MODULE__), data, __ENV__)
    end
  end
  defmacro test(name, [do: _]) do
    Logger.error("""
    test #{inspect(name)} missing 'after' block with assertions (#{__CALLER__.file}:#{__CALLER__.line})

    it should look something like

        test #{inspect(name)} do
          request do

          end
        after conn ->
          conn
          |> assert_status(200)
        end
    """)
    throw :missing_assertions_block
  end

  def compile(_, _) do
    nil
  end

  def compile_global(tests, env) do
    tests
    |> do_compile(env, Mix.env)
  end

  defp do_compile(_tests, _env, :dev) do
    quote do
      @doc false
      def tests(_), do: []
    end
  end
  defp do_compile(tests, env, _) do
    module = env.module
    quote do
      @doc false
      def __mazurka_test__() do
        unquote(Enum.map(tests, fn({{name, _, _, tags}, env}) -> Macro.escape({module, name, tags, env}) end))
      end

      unquote_splicing(Enum.map(tests, &compile_test/1))
    end
  end

  def compile_test({{name, block, assertions, _}, _}) do
    {variables, seed, create_conn} = compile_block(block)
    assertions = compile_assertions(assertions, variables)

    quote do
      def __mazurka_test__(unquote(name), unquote(__router__)) do
        import Kernel
        import Mazurka.Compiler.Kernel, only: []
        {unquote(variables), unquote(seed), unquote(create_conn), unquote(assertions)}
      end
    end
  end

  defp compile_block({:__block__, _, list}) do
    compile_block(list)
  end
  defp compile_block(list) when is_list(list) do
    {seed, request} = Enum.split_while(list, fn
      ({:request, _, _}) -> false
      (_) -> true
    end)

    {variables, seed} = compile_seed(seed)
    {variables, seed, compile_request(request, variables)}
  end
  defp compile_block(expression) do
    compile_block([expression])
  end

  defp compile_seed(seed) do
    {variables, expressions} = Enum.reduce(seed, {[], []}, &compile_seed_expression/2)
    {variables, quote do
      fn
        (unquote(__context__)) ->
          import Mazurka.Resource.Test.Seed

          unquote_splicing(Enum.reverse(expressions))
          unquote(__context__)
      end
    end}
  end

  defp compile_seed_expression({:=, _, [{name, _, context}, rhs]}, {variables, expressions}) when is_atom(context) do
    expr = quote do
      %{unquote(name) => unquote(Macro.var(name, nil))} = unquote(__context__) = unquote(put_new_lazy(name, rhs))
    end
    {[name | variables], [expr | expressions]}
  end
  defp compile_seed_expression({:=, _, _} = expr, _) do
    throw {:unsupported_seed_expression, Macro.to_string(expr)}
  end
  defp compile_seed_expression(other, {variables, expressions}) do
    {variables, [other | expressions]}
  end

  defp compile_request([], _variables) do
    throw :missing_request_block
  end
  defp compile_request(request, variables) do
    quote do
      fn
        (unquote(variables_to_map(variables))) ->
          import Mazurka.Resource.Test.Request, only: [request: 0, request: 1]
          unquote_splicing(request)
        (context) ->
          IO.puts "Missing " <> inspect(unquote(variables) -- Map.keys(context))
          throw :error
      end
    end
  end

  defp compile_assertions(assertions, variables) do
    map = variables_to_map(variables)
    quote do
      use Mazurka.Resource.Test.Assertions
      unquote({:fn, [], Enum.map(assertions, fn({:->, meta, [[conn], body]}) ->
        {:->, meta, [[conn, map], body]}
      end)})
    end
  end

  defp variables_to_map(variables) do
    {:%{}, [], Enum.map(variables, &{&1, Macro.var(&1, nil)})}
  end

  defp put_new_lazy(name, fun) do
    quote do
      case unquote(__context__) do
        %{unquote_splicing([{name, Macro.var(:_, nil)}])} = context ->
          context
        context ->
          Map.put(context, unquote(name), unquote(fun))
      end
    end
  end

  defp __router__ do
    Macro.var(:__router__, nil)
  end

  defp __context__ do
    Macro.var(:__context__, nil)
  end
end

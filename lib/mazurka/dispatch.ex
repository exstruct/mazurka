defmodule Mazurka.Dispatch do
  alias Mazurka.Compiler.Utils

  defmacro __using__(_opts) do
    quote do
      import Mazurka.Dispatch
      @before_compile Mazurka.Dispatch

      defmacro __using__(_) do
        dispatch = __MODULE__
        quote do
          def call(conn, opts) do
            conn = conn
            |> Plug.Conn.put_private(:mazurka_dispatch, unquote(dispatch))
            |> Plug.Conn.put_private(:mazurka_router, __MODULE__)
            super(conn, opts)
          end
        end
      end

      use Mazurka.Dispatch.BuiltIn

      def resolve(module, function, arguments, conn, parent, ref, attrs) do
        do_resolve(module, function, arguments, conn, parent, ref, attrs)
      end
    end
  end

  defmacro __before_compile__(_) do
    quote do
      defp do_resolve(module, function, args, _conn, _parent, _ref, _attrs) do
        raise %UndefinedFunctionError{module: module, function: function, arity: length(args)}
      end
    end
  end

  defmacro env(_env, [do: _block]) do
    nil
  end

  defmacro service(definition) do
    quote do
      service unquote(definition), do: []
    end
  end

  defmacro service(definition, [do: _] = do_block) do
    case unescape(definition, __CALLER__) do
      {module, function, arity} ->
        args = gen_pos_args(arity)
        quote do
          service unquote(definition), unquote(module).unquote(function)(unquote_splicing(args)), unquote(do_block)
        end
      _ ->
        quote do
          service unquote(definition), unquote(definition), unquote(do_block)
        end
    end
  end

  defmacro service(source, target) do
    quote do
      service unquote(source), unquote(target), do: []
    end
  end

  defmacro service(source, target, [do: _middleware]) do
    case {unescape(source, __CALLER__), unescape(target, __CALLER__)} do
      {{s_module, s_function, s_arity}, {t_module, t_function, t_args}} ->
        s_args = gen_args(s_arity)
        quote do
          defp do_resolve(unquote(s_module), unquote(s_function), unquote(s_args), var!(_conn), var!(_parent), var!(_ref), var!(_attrs)) do
            unquote(t_module).unquote(t_function)(unquote_splicing(t_args))
          end
        end
      {s_module, t_module} ->
        quote do
          defp do_resolve(unquote(s_module), function, args, var!(_conn), var!(_parent), var!(_ref), var!(_attrs)) do
            apply(unquote(t_module), function, args)
          end
        end
    end
  end

  defp gen_args(arity) do
    :lists.seq(1, arity)
    |> Enum.map(&var/1)
  end

  defp gen_pos_args(arity) do
    :lists.seq(1, arity)
    |> Enum.map(fn(i) ->
      {:&, [], [i]}
    end)
  end

  defp unescape({:/, _, [{{:., _, [module, function]}, _, _}, arity]}, caller) do
    module = Utils.eval(module, caller)
    function = Utils.eval(function, caller)
    {module, function, arity}
  end
  defp unescape({:__aliases__, _, _} = module, caller) do
    Utils.eval(module, caller)
  end
  defp unescape({{:., _meta, [module, function]}, _, args}, caller) do
    module = Utils.eval(module, caller)
    function = Utils.eval(function, caller)
    args = Enum.map(args, fn
      ({:&, _, [item]}) ->
        var(item)
      ({:self, _, _}) ->
        Macro.var(:_self, nil)
      ({:conn, _, _}) ->
        Macro.var(:_conn, nil)
      ({:ref, _, _}) ->
        Macro.var(:_ref, nil)
      ({:env, _, _}) ->
        quote do
          var!(_conn).private[:mazurka_env] || :prod
        end
      (other) ->
        Utils.eval(other, caller) |> Macro.escape
    end)
    {module, function, args}
  end

  defp var(i) do
    "_arg_#{i}"
    |> String.to_atom
    |> Macro.var(nil)
  end
end
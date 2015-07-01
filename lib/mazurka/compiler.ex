defmodule Mazurka.Compiler do
  alias Mazurka.Compiler.Utils

  @doc """
  Compile a resource with the environment attributes
  """
  defmacro compile(env) do
    globals = compile_globals(env)
    mediatypes = compile_mediatypes(globals, env)
    struct = compile_struct(globals, env)
    body(env.module, mediatypes, struct)
  end

  @doc false
  defp body(module, mediatypes, struct) do
    quote do
      @doc """
      Handle a given request
      """
      def action(request, resolve) do
        handle("*", "*", %{}, request, resolve)
      end

      @doc """
      Handle a given request, passing a list of acceptable mediatypes
      """
      def action(request, resolve, []) do
        {:error, :unacceptable}
      end
      def action(request, resolve, [{_, {type, subtype, params}} | accepts]) do
        case handle(type, subtype, params, request, resolve) do
          {:error, :unacceptable} ->
            action(request, resolve, accepts)
          res ->
            res
        end
      end
      def action(request, resolve, [{type, subtype, params} | accepts]) do
        case handle(type, subtype, params, request, resolve) do
          {:error, :unacceptable} ->
            action(request, resolve, accepts)
          res ->
            res
        end
      end

      @doc """
      Render an affordance partial
      """
      def affordance_partial(context, resolve, req, scope, props) do
        {type, subtype, params} = Mazurka.Runtime.get_mediatype(context)
        affordance(type, subtype, params, context, resolve, req, scope, props)
      end

      @doc false
      defp handle(type, subtype, params, request, resolve)
      defp affordance(type, subtype, params, context, resolve, req, scope, props)
      unquote_splicing(mediatypes)
      defp handle(_, _, _, _, _) do
        {:error, :unacceptable}
      end

      defp affordance(type, subtype, _, context, _, _, _, _) do
        ## TODO should we throw an exception? or fail silently?
        ##      for now we fail silently.
        Logger.info("no acceptable affordance was found for #{type}/#{subtype} in #{unquote(module)}")
        {{:__ETUDE_READY__, :undefined}, context}
      end

      def __struct__() do
        unquote(Macro.escape(struct))
      end
    end
  end

  defp compile_mediatypes(globals, env) do
    Module.get_attribute(env.module, :mz_mediatype)
    |> Utils.eval(env)
    |> compile_mediatypes(globals, env, [])
  end

  defp compile_mediatypes([], globals, _, acc) do
    :lists.reverse(acc)
  end
  defp compile_mediatypes([mediatype | rest], globals, env, []) do
    opts = %{first: true}
    compiled = Mazurka.Compiler.Mediatype.compile(mediatype, globals, env, opts)
    compile_mediatypes(rest, globals, env, compiled)
  end
  defp compile_mediatypes([mediatype | rest], globals, env, acc) do
    opts = %{}
    compiled = Mazurka.Compiler.Mediatype.compile(mediatype, globals, env, opts)
    compile_mediatypes(rest, globals, env, compiled ++ acc)
  end

  defp compile_struct(globals, env) do
    params = Enum.map(globals.params || [], fn
      ({{name, _, _}, _}) ->
        {name, nil}
    end)
    [{:__struct__, Mazurka.Mediatype.Affordance} | params]
    |> :maps.from_list
  end

  defp compile_globals(env) do
    %{
      conditions: Mazurka.Resource.Condition.attribute,
      events: Mazurka.Resource.Event.attribute,
      lets: Mazurka.Resource.Let.attribute,
      params: Mazurka.Resource.Param.attribute,
    }
    |> Enum.reduce(%{}, fn({key, name}, acc) ->
      values = Module.get_attribute(env.module, name) |> format_global(key, env)
      Dict.put(acc, key, values)
    end)
  end

  def format_global(nil, :conditions, _env) do
    true
  end
  def format_global([clause], :conditions, _env) do
    clause
  end
  def format_global([clause | rest], :conditions, _env) do
    {:&&, [], [clause, format_global(rest, :conditions, _env)]}
  end
  def format_global(nil, :lets, _env) do
    []
  end
  def format_global(nil, :params, _env) do
    []
  end
  def format_global(global, _, _env) do
    global
  end
end

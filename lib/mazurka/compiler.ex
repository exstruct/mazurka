defmodule Mazurka.Compiler do
  alias Mazurka.Compiler.Utils

  @doc """
  Compile a resource with the environment attributes
  """
  defmacro compile(env) do
    {mediatypes, globals} = Utils.get(env)
    |> partition({%{}, %{}})

    globals = globals
    |> Enum.map(&prepare_global/1)
    |> :maps.from_list

    mediatypes = Enum.flat_map(mediatypes, &(prepare_mediatype(&1, globals, env)))

    body(env.module, mediatypes, [])
  end

  defp partition(list, acc) when list == [] or list == nil do
    acc
  end
  defp partition([{nil, name, ast, meta} | rest], {mediatypes, globals}) do
    globals = put_acc(globals, name, ast, meta)
    partition(rest, {mediatypes, globals})
  end
  defp partition([{mediatype, name, ast, meta} | rest], {mediatypes, globals}) do
    mt = mediatypes
    |> Dict.get(mediatype, %{__default__: Dict.size(mediatypes) == 0})
    |> put_acc(name, ast, meta)

    mediatypes = Dict.put(mediatypes, mediatype, mt)
    partition(rest, {mediatypes, globals})
  end

  defp put_acc(map, name, ast, meta) do
    acc = Dict.get(map, name, [])
    acc = [{ast, meta} | acc]
    Dict.put(map, name, acc)
  end

  defp prepare_global({global, definitions}) do
    key = format_name(global)
    {key, global.compile(definitions)}
  end

  defp prepare_mediatype({mediatype, definitions}, globals, env) do
    # default = if Dict.get(definitions, :__default__) do
    #   [{"*", "*", %{}}]
    # else
    #   []
    # end

    definitions = Dict.delete(definitions, :__default__)
    definitions = Enum.flat_map(definitions, &(prepare_definition(&1, mediatype, globals)))

    module = env.module
    etude_module = Module.concat([module, Etude])

    beam = definitions
    |> Utils.expand(env)
    |> Mazurka.Compiler.Etude.elixir_to_etude(etude_module)
    |> compile(etude_module, env)

    for {type, subtype, params, content_type} <- mediatype.content_types() do
      params = Macro.escape(params)
      # TODO send params as well
      resp_type = "#{type}/#{subtype}; charset=utf-8"
      quote do
        defp handle(unquote(type) = type, unquote(subtype) = subtype, unquote(params) = params, context, resolve) do
          context = Mazurka.Runtime.put_mediatype(context, {type, subtype, params})
          Logger.debug("handling request with #{type}/#{subtype} in #{unquote(module)}")
          prev = :erlang.get()
          {out, context} = unquote(etude_module).action(context, resolve)
          :erlang.erase()
          for {k, v} <- prev do
            :erlang.put(k, v)
          end
          {:ok, unquote(content_type).encode(out), context, unquote(resp_type)}
        end

        defp affordance(unquote(type), unquote(subtype), unquote(params), context, resolve, req, scope, props) do
          unquote(etude_module).affordance_partial(context, resolve, req, scope, props)
        end
      end
    end
  end

  defp prepare_definition({handler, [{ast, meta}]}, mediatype, globals) do
    fn_name = format_name(handler)
    [{fn_name, handler.compile(mediatype, ast, globals, meta)}]
  end
  defp prepare_definition({handler, definitions}, mediatype, globals) do
    fn_name = format_name(handler)
    for {ast, meta} <- definitions do
      {fn_name, handler.compile(mediatype, ast, globals, meta)}
    end
  end

  defp format_name(handler) do
    handler |> Module.split |> List.last |> String.downcase |> String.to_atom
  end

  defp compile(etude_ast, etude_module, env) do
    {:ok, _, _, beam} = Etude.compile(etude_module, etude_ast, [file: env.file])
    "#{Mix.Project.compile_path}/#{etude_module}.beam"
    |> File.write!(beam)
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

      def __struct__ do
        unquote(Macro.escape(struct))
      end
    end
  end

end

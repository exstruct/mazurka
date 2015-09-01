defmodule Mazurka.Compiler do
  alias Mazurka.Compiler.Utils

  @doc """
  Compile a resource with the environment attributes
  """
  defmacro compile(env) do
    {mediatypes, includes, globals} = Utils.get(env)
    |> partition({%{}, %{}, %{}})

    includes = includes
    |> Enum.map(&(prepare_include(&1, env)))
    |> :maps.from_list

    globals = globals
    |> Dict.put_new(Mazurka.Resource.Param, [])
    |> Dict.put_new(Mazurka.Resource.Test, [])
    |> Enum.map(&(prepare_global(&1, env)))

    etude_modules = Enum.map(mediatypes, &(prepare_etude_module(&1, includes, env)))
    clauses = Enum.flat_map(etude_modules, &(prepare_clauses(&1, env)))

    body(env.module, clauses, globals)
  end

  defp partition(list, acc) when list == [] or list == nil do
    acc
  end
  defp partition([{nil, name, ast, meta} | rest], {mediatypes, includes, globals}) do
    name.module_info()
    globals = if :erlang.function_exported(name, :compile_global, 2) do
      put_acc(globals, name, ast, meta)
    else
      globals
    end
    includes = put_acc(includes, name, ast, meta)
    partition(rest, {mediatypes, includes, globals})
  end
  defp partition([{mediatype, name, ast, meta} | rest], {mediatypes, includes, globals}) do
    mt = mediatypes
    |> Dict.get(mediatype, %{__default__: Map.size(mediatypes) == 0})
    |> put_acc(name, ast, meta)

    mediatypes = Dict.put(mediatypes, mediatype, mt)
    partition(rest, {mediatypes, includes, globals})
  end

  defp put_acc(map, name, ast, meta) do
    acc = Dict.get(map, name, [])
    acc = [{ast, meta} | acc]
    Dict.put(map, name, acc)
  end

  defp prepare_include({include, definitions}, env) do
    key = format_name(include)
    {key, include.compile(definitions, env)}
  end

  defp prepare_global({global, definitions}, env) do
    global.compile_global(definitions, env)
  end

  defp prepare_etude_module({mediatype, definitions}, includes, env) do
    module = env.module
    etude_module = Module.concat([module, mediatype.name])

    is_default = Map.get(definitions, :__default__)

    content_types = definitions
    |> Map.get(Mazurka.Resource.Provides)
    |> Mazurka.Resource.Provides.format_types(mediatype.content_types())

    definitions
    |> Map.delete(:__default__)
    |> Map.put_new(Mazurka.Resource.Action, [Mazurka.Resource.Action.default(module)])
    |> Map.put_new(Mazurka.Resource.Affordance, [Mazurka.Resource.Affordance.default(module)])
    |> Enum.flat_map(&(prepare_definition(&1, mediatype, includes)))
    |> Utils.expand(%{env | module: etude_module})
    |> Mazurka.Compiler.Etude.elixir_to_etude(etude_module)
    |> compile(etude_module, env)

    {mediatype, content_types, etude_module, is_default}
  end

  defp prepare_clauses({mediatype, content_types, etude_module, is_default}, env) do
    module = env.module
    [{default_type, default_subtype, default_params, _} | _] = content_types
    for {type, subtype, params, content_type} <- content_types do
      params = Macro.escape(params)
      # TODO format params as well
      resp_type = "#{type}/#{subtype}"
      quote do
        defp handle(unquote(type) = type, unquote(subtype) = subtype, unquote(params) = params, context, resolve) do
          context = Mazurka.Runtime.put_mediatype(context, unquote(mediatype), {type, subtype, params})
          Logger.debug("handling request with #{type}/#{subtype} in #{unquote(module)}")
          prev = :erlang.get()
          {out, context} = try do
            unquote(etude_module).action(context, resolve)
          rescue
            err in Mazurka.Resource.Error ->
              {err.message, err.state}
            err in Etude.Exception ->
              clear_cache(prev)
              Plug.Conn.WrapperError.reraise(err.state, :error, err.error)
            e ->
              clear_cache(prev)
              reraise(e, System.stacktrace())
          end
          clear_cache(prev)

          # encode the response with the content type
          out = if out != nil do
            unquote(content_type).encode(out)
          else
            out
          end

          {:ok, out, context, unquote(resp_type)}
        end

        defp affordance(unquote(type), unquote(subtype), unquote(params), context, resolve, req, scope, props) do
          unquote(etude_module).affordance_partial(context, resolve, req, scope, props)
        end
      end
    end ++ if is_default do
      [quote do
        defp handle("*", "*", _, context, resolve) do
          handle(unquote(default_type), unquote(default_subtype), unquote(Macro.escape(default_params)), context, resolve)
        end
      end]
    else
      []
    end
  end

  defp prepare_definition({handler, definitions}, mediatype, globals) do
    for {ast, meta} <- definitions do
      fn_name = format_name(handler, meta)
      {fn_name, handler.compile(mediatype, ast, globals, meta)}
    end
  end

  defp format_name(handler, meta \\ nil)
  defp format_name(handler, nil) do
    handler |> Module.split |> List.last |> String.downcase |> String.to_atom
  end
  defp format_name(handler, meta) do
    handler.module_info()
    if :erlang.function_exported(handler, :format_name, 1) do
      handler.format_name(meta)
    else
      format_name(handler, nil)
    end
  end

  defp compile(etude_ast, etude_module, env) do
    ## TODO read the existing beam file and verify it has changed before compiling
    {:ok, _, _, beam} = Etude.compile(etude_module, etude_ast, [file: env.file, native: Mix.env == :prod])

    # Make ex_doc happy
    chunk_data = :erlang.term_to_binary({:elixir_docs_v1, [
      docs: [],
      moduledoc: {0, false},
      behaviour_docs: []
    ]})
    beam = :elixir_module.add_beam_chunk(beam, 'ExDc', chunk_data)

    path = "#{Mix.Project.compile_path}/#{etude_module}.beam"

    File.write!(path, beam)
    :code.load_binary(etude_module, env.file |> to_char_list, beam)
  end

  @doc false
  defp body(module, mediatypes, globals) do
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
        handle("*", "*", %{}, request, resolve)
      end
      def action(request, resolve, [{_, {type, subtype, params}}]) do
        handle(type, subtype, params, request, resolve)
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

      @doc false
      def affordance_partial(context, resolve, req, scope, props) do
        {type, subtype, params} = Mazurka.Runtime.get_mediatype(context)
        affordance(type, subtype, params, context, resolve, req, scope, props)
      end

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

      defp clear_cache(prev) do
        :erlang.erase()
        for {k, v} <- prev do
          :erlang.put(k, v)
        end
      end

      unquote_splicing(globals)
    end
  end

end

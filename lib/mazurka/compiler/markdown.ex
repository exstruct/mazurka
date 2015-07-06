defmodule Mazurka.Compiler.Markdown do
  def compile(ast, src, _opts \\ []) do
    ## TODO set default sections if they don't exist

    mod = ast[:name]
    {sections, mediatypes, has_affordance} = Enum.reduce(ast[:children], {%{}, [], false}, &(gather_sections(mod, &1, src, &2)))

    quoted = Enum.map(sections, &compile_section/1)

    vsn = :erlang.phash2({System.version, quoted})

    out = quote do
      defmodule unquote(mod) do
        @file unquote(src)
        @moduledoc unquote(ast[:docs])
        @vsn unquote(vsn)
        unquote_splicing(quoted)
        unquote(if !has_affordance do
          quote do
            def affordance_partial(context, _, _, _, _) do
              {{:__ETUDE_READY__, :undefined}, context}
            end
          end
        end)
      end
    end
    [{mod, lazy_compile_main(out, src, vsn), :main} | mediatypes]
  end

  defp compile_section({name, section}) do
    exec = "#{name}_exec" |> String.to_atom
    partial = name |> Mazurka.Mediatype.Parser.Utils.partial_name
    {quoted, _} = Enum.map_reduce(section, true, &(compile_mediatype(exec, partial, &1, &2)))

    quote do
      def unquote(name)(context, resolve, accepts \\ [])
      def unquote(name)(context, resolve, []) do
        unquote(exec)("*", "*", %{}, context, resolve)
      end
      def unquote(name)(context, resolve, [{_, {type, subtype, params}} | accepts]) do
        case unquote(exec)(type, subtype, params, context, resolve) do
          {:error, :unacceptable} ->
            unquote(name)(context, resolve, accepts)
          res ->
            res
        end
      end
      def unquote(name)(context, resolve, [{type, subtype, params} | accepts]) do
        case unquote(exec)(type, subtype, params, context, resolve) do
          {:error, :unacceptable} ->
            unquote(name)(context, resolve, accepts)
          res ->
            res
        end
      end
      def unquote(partial)(context, resolve, req, scope, props) do
        {type, subtype, params} = Mazurka.Runtime.get_mediatype(context)
        unquote(partial)(type, subtype, params, context, resolve, req, scope, props)
      end

      defp unquote(exec)(type, subtype, params, context, resolve)
      defp unquote(partial)(type, subtype, params, context, resolve, req, scope, props)
      unquote_splicing(quoted)
      defp unquote(exec)(_, _, _, _, _) do
        {:error, :unacceptable}
      end

      defp unquote(partial)(_type, _subtype, _params, context, _resolve, _req, _scope, _props) do
        {{:__ETUDE_READY__, :undefined}, context}
      end
    end
  end

  defp compile_mediatype(exec, partial, {{type, subtype, _params}, conf}, is_first) do
    exec_module = Keyword.get(conf, :module)
    serialize_module = Keyword.get(conf, :serialize)
    ## TODO append params
    mediatype = "#{type}/#{subtype}"
    {quote do
      defp unquote(exec)(unquote(type), unquote(subtype), params, context, resolve) do
        unquote(put_mediatype(serialize_module, type, subtype))
        unquote(exec(exec_module, serialize_module, mediatype))
      end
      defp unquote(partial)(unquote(type), unquote(subtype), _params, context, resolve, req, scope, props) do
        unquote(exec_module).exec_partial(context, resolve, req, scope, props)
      end
      unquote(if is_first do
        quote do
          defp unquote(exec)(unquote(type), "*", params, context, resolve) do
            unquote(put_mediatype(serialize_module, type, subtype))
            unquote(exec(exec_module, serialize_module, mediatype))
          end
          defp unquote(exec)("*", "*", params, context, resolve) do
            unquote(put_mediatype(serialize_module, type, subtype))
            unquote(exec(exec_module, serialize_module, mediatype))
          end
        end
      end)
    end, false}
  end

  defp put_mediatype(mediatype, type, subtype) do
    quote do
      context = Mazurka.Runtime.put_mediatype(context, unquote(mediatype), {unquote(type), unquote(subtype), params})
    end
  end

  defp exec(exec, serialize, mediatype) do
    quote do
      prev = :erlang.get()
      out = case unquote(exec).exec(context, resolve) do
        {out, context} ->
          {:ok, unquote(serialize).serialize(out), context, unquote(mediatype)}
        ## TODO check if there is an error handler for this resource and render that
        error ->
          error
      end
      :erlang.erase()
      for {k, v} <- prev do
        :erlang.put(k, v)
      end
      out
    end
  end

  defp gather_sections(mod, mediatype, src, acc) do
    types = mediatype[:types]
    parsed_types = Enum.map(types, &parse_type/1)
    mediatype[:children]
    |> Enum.reduce(acc, &(gather_section(&1, mod, src, types, parsed_types, &2)))
  end

  defp gather_section(section, mod, src, types, parsed_types, {confs, mediatypes, has_affordance}) do
    name = section[:name]
    parser = section[:parser] && [section[:parser]] || []
    parsers = parser ++ types
    line = Dict.get(section, :line, 1)
    {:ok, ast, serialize_module} = Mazurka.Mediatype.Parser.parse(line, src, section[:code], parsers)

    [chosen | _] = parsers
    ## TODO replace unsafe characters here
    exec_module = "#{mod}_#{chosen}_#{name}" |> String.to_atom

    conf = [module: exec_module,
            serialize: serialize_module,
            docs: section[:docs]]

    confs = Enum.reduce(parsed_types, confs, fn(type, acc) ->
      section = Dict.get(acc, name, []) ++ [{type, conf}]
      Dict.put(acc, name, section)
    end)

    has_affordance = has_affordance || name == :affordance

    {confs, [{exec_module, lazy_compile(exec_module, ast, src), "#{chosen} #{name}"} | mediatypes], has_affordance}
  end

  def lazy_compile(exec_module, ast, src) do
    fn(opts) ->
      Etude.compile_lazy(exec_module, [exec: ast], extend_opts(opts, src))
    end
  end

  defp extend_opts(opts, src) do
    [file: src, function: :exec] ++ opts
  end

  def lazy_compile_main(out, src, vsn) do
    fn(_opts) ->
      {vsn, fn ->
        case quoted_to_beam(out, src) do
          {mod, bin} when is_binary(bin) ->
            {:ok, mod, :main, bin}
          other ->
            other
        end
      end}
    end
  end

  defp parse_type(type) do
    {:ok, [out]} = :mimetype_parser.parse(type)
    out
  end

  # this is a pretty nasty hack since elixir can't just compile something without loading it
  defp quoted_to_beam(ast, src) do
    before = Code.compiler_options
    updated = Keyword.put(before, :ignore_module_conflict, :true)
    Code.compiler_options(updated)
    [{name, bin}] = Code.compile_quoted(ast, src)
    Code.compiler_options(before)
    maybe_reload(name)
    {name, bin}
  end

  defp maybe_reload(module) do
    case :code.which(module) do
      atom when is_atom(atom) ->
        # Module is likely in memory, we purge as an attempt to reload it
        :code.purge(module)
        :code.delete(module)
        Code.ensure_loaded?(module)
        :ok
      _file ->
        :ok
    end
  end
end
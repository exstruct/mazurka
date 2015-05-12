defmodule Mazurka.Compiler.Resource do
  alias Mazurka.Compiler.Utils

  def compile(ast, src, _opts \\ []) do
    ## TODO set default sections if they don't exist

    mod = ast[:name]
    {sections, mediatypes} = Enum.reduce(ast[:children], {%{}, []}, &(gather_sections(mod, &1, src, &2)))

    quoted = Enum.map(sections, &compile_section/1)

    vsn = :erlang.phash2(quoted)

    out = quote do
      defmodule unquote(mod) do
        @file unquote(src)
        @moduledoc unquote(ast[:docs])
        @vsn unquote(vsn)
        unquote_splicing(quoted)
      end
    end
    [{mod, Utils.quoted_to_beam(out, src), lazy_stale_main(vsn), :main} | mediatypes]
  end

  defp compile_section({name, section}) do
    exec = "#{name}_exec" |> String.to_atom
    partial = name |> Mazurka.Mediatype.Utils.partial_name
    {quoted, _} = Enum.map_reduce(section, true, &(compile_mediatype(exec, partial, &1, &2)))

    quote do
      @doc unquote(compile_docs(name, section))
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

      defp unquote(exec)(type, subtype, params, context, resolve)
      def unquote(partial)(type, subtype, params, context, resolve, req, scope, props)
      unquote_splicing(quoted)
      defp unquote(exec)(_, _, _, _, _) do
        {:error, :unacceptable}
      end

      def unquote(partial)(_type, _subtype, _params, context, _resolve, _req, _scope, _props) do
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
        unquote(put_mediatype(type, subtype))
        unquote(exec(exec_module, serialize_module, mediatype))
      end
      def unquote(partial)(unquote(type), unquote(subtype), _params, context, resolve, req, scope, props) do
        unquote(exec_module).exec_partial(context, resolve, req, scope, props)
      end
      unquote(if is_first do
        quote do
          defp unquote(exec)(unquote(type), "*", params, context, resolve) do
            unquote(put_mediatype(type, subtype))
            unquote(exec(exec_module, serialize_module, mediatype))
          end
          defp unquote(exec)("*", "*", params, context, resolve) do
            unquote(put_mediatype(type, subtype))
            unquote(exec(exec_module, serialize_module, mediatype))
          end
        end
      end)
    end, false}
  end

  defp put_mediatype(type, subtype) do
    quote do
      context = Mazurka.Mediatype.Utils.put_mediatype(context, {unquote(type), unquote(subtype), params})
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

  defp gather_section(section, mod, src, types, parsed_types, {confs, mediatypes}) do
    name = section[:name]
    parser = section[:parser] && [section[:parser]] || []
    parsers = parser ++ types
    line = Dict.get(section, :line, 1)
    {:ok, ast, serialize_module} = Mazurka.Mediatype.parse(line, src, section[:code], parsers)

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

    {confs, [{exec_module, lazy_compile(exec_module, ast, src), lazy_stale(ast, src), "#{chosen} #{name}"} | mediatypes]}
  end

  def lazy_compile(exec_module, ast, src) do
    fn(opts) ->
      case Etude.compile(exec_module, ast, extend_opts(opts, src)) do
        {:ok, _, _, beam} ->
          {exec_module, beam}
        error ->
          error
      end
    end
  end

  def lazy_stale(ast, src) do
    fn(target, opts) ->
      Mazurka.Compiler.Utils.is_target_stale?(target, Etude.vsn(ast, extend_opts(opts, src)))
    end
  end

  defp extend_opts(opts, src) do
    [file: src, function: :exec] ++ opts
  end

  def lazy_stale_main(vsn) do
    fn(target, _opts) ->
      Mazurka.Compiler.Utils.is_target_stale?(target, vsn)
    end
  end

  def compile_docs(name, section) do
    type_docs = section
    |> Enum.map(fn({type, section}) ->
      """
      ### #{format_type(type)}

      * [IANA](http://www.iana.org/assignments/media-types/#{format_type(type, false)})

      #{section[:docs]}
      """
    end)
    |> Enum.join("\n")

    """
    #{name} handler

    ## Provided Media Types

    #{type_docs}
    """
  end

  defp parse_type(type) do
    {:ok, [out]} = :mimetype_parser.parse(type)
    out
  end

  defp format_type(type_tuple, include_params \\ true)

  defp format_type({type, subtype, params}, include_params) when params == %{} or not include_params do
    "#{type}/#{subtype}"
  end
  defp format_type({type, subtype, params}, _) do
    p = params
    |> Enum.map(fn({key, value}) ->
      "#{key}=#{value}"
    end)
    |> Enum.join(", ")
    "#{type}/#{subtype};#{p}"
  end
end
defmodule Mazurka.Compiler.Resource do
  alias Mazurka.Compiler.Utils

  def compile(ast, src, opts \\ []) do
    ## TODO set default sections if they don't exist

    mod = ast[:name]
    {sections, mediatypes} = Enum.reduce(ast[:children], {%{}, []}, &(gather_sections(mod, &1, src, &2)))

    quoted = Enum.map(sections, &(compile_section(mod, src, &1)))

    out = quote do
      defmodule unquote(mod) do
        @file unquote(src)
        @moduledoc unquote(ast[:docs])
        unquote_splicing(quoted)
      end
    end
    [{mod, Utils.quoted_to_beam(out, src), :main} | mediatypes]
  end

  defp compile_section(mod, src, {name, section}) do
    exec = "#{name}_exec" |> String.to_atom
    {quoted, _} = Enum.map_reduce(section, true, &(compile_mediatype(mod, exec, src, &1, &2)))

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
      unquote_splicing(quoted)
      defp unquote(exec)(_, _, _, _, _) do
        {:error, :unacceptable}
      end
    end
  end

  defp compile_mediatype(mod, exec, src, {{type, subtype, _params}, conf}, is_first) do
    exec_module = Keyword.get(conf, :module)
    serialize_module = Keyword.get(conf, :serialize)
    ## TODO append params
    mediatype = "#{type}/#{subtype}"
    {quote do
      defp unquote(exec)(unquote(type), unquote(subtype), _params, context, resolve) do
        case unquote(exec_module).exec(context, resolve) do
          {out, context} ->
            {:ok, unquote(serialize_module).serialize(out), context, unquote(mediatype)}
          ## TODO check if there is an error handler for this resource and render that
          error ->
            error
        end
      end
      unquote(if is_first do
        quote do
          defp unquote(exec)(unquote(type), "*", _params, context, resolve) do
            case unquote(exec_module).exec(context, resolve) do
              {out, context} ->
                {:ok, unquote(serialize_module).serialize(out), context, unquote(mediatype)}
              ## TODO check if there is an error handler for this resource and render that
              error ->
                error
            end
          end
          defp unquote(exec)("*", "*", _params, context, resolve) do
            case unquote(exec_module).exec(context, resolve) do
              {out, context} ->
                {:ok, unquote(serialize_module).serialize(out), context, unquote(mediatype)}
              ## TODO check if there is an error handler for this resource and render that
              error ->
                error
            end
          end
        end
      end)
    end, false}
  end

  def gather_sections(mod, mediatype, src, acc) do
    types = mediatype[:types]
    parsed_types = Enum.map(types, &parse_type/1)
    mediatype[:children]
    |> Enum.reduce(acc, &(gather_section(&1, mod, src, types, parsed_types, &2)))
  end

  def gather_section(section, mod, src, types, parsed_types, {confs, mediatypes}) do
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

    {confs, [{exec_module, lazy_compile(exec_module, ast, src), "#{chosen} #{name}"} | mediatypes]}
  end

  def lazy_compile(exec_module, ast, src) do
    fn(opts) ->
      case Etude.compile(exec_module, ast, [file: src, function: :exec] ++ opts) do
        {:ok, _, _, beam} ->
          {exec_module, beam}
        error ->
          error
      end
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
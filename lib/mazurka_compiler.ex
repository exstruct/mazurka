defmodule Mazurka.Compiler do
  def parse(src, opts) do
    :mazurka_dsl.parse_file(src, opts)
  end

  def compile_file(src, dest, opts) do
    try do
      {:ok, resources} = parse(src, opts)
      beams = Enum.map(resources, fn(resource) ->
        compile_resource(resource, src, dest)
      end)
      {:ok, beams}
    rescue
      e -> {:error, e}
    end
  end

  def compile_resource(resource, src, dest) do
    ast = generate(resource)
    {name, bin} = to_beam(ast, src)
    out = Path.join(dest, "#{name}.beam")
    File.write(out, bin)
    {:ok, {name, out}}
  end

  # this is a pretty nasty hack since elixir can't just compile something without loading it
  def to_beam(ast, src) do
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

  def generate(ast) do
    quote do
      defmodule unquote(ast[:name]) do
        @moduledoc unquote(ast[:docs])

        @doc """
        accepts should be a list of acceptable types

            []

            [{\"text\", \"html\", %{}} | _]

            [{\"*\", \"json\", %{}} | _]

            [{\"*\", \"*\", %{:profile => \"vendor.org.type\"}} | _]
        """
        def handle([], _, _) do
          {:error, :unacceptable}
        end
        def handle([{type, subtype, params} | accepts], resolve, context) do
          case do_handle(type, subtype, params, resolve, context) do
            {:error, :unacceptable} -> handle(accepts, resolve, context)
            res -> res
          end
        end

#        unquote(gen_do_handle(ast[:children], []))

        defp do_handle(_, _, _, _, _) do
          {:error, :unacceptable}
        end

        def supported_actions do
          unquote(gen_supported_types_map(ast[:children], :action, 2))
        end

        # def supported_affordances do
        #   unquote(gen_supported_types_map(ast[:children], :affordance, 2))
        # end

        unquote(Enum.map(ast[:children], &gen_child/1))
      end
    end
  end

  def gen_do_handle([], acc) do
    acc
  end
  def gen_do_handle([child | children], []) do
    [type | rest] = child[:types]
    name = gen_name(child, :action)
    {:ok, [res]} = expand_type(type)
    child = Map.put(child, :types, rest)
    gen_do_handle([child | children], [gen_do_handle_type(name, res, :first)])
  end
  def gen_do_handle([child | children], acc) do
    acc = acc ++ Enum.map(child[:types], fn(type) ->
      name = gen_name(child, :action)
      {:ok, [res]} = expand_type(type)
      gen_do_handle_type(name, res, :not_first)
    end)
    gen_do_handle(children, acc)
  end

  def gen_do_handle_type(name, type, :first) do
    prev = gen_do_handle_type(name, type, :not_first)
    [quote do
      defp do_handle("*", "*", %{}, resolve, context) do
        unquote(name)(resolve, context)
      end
    end | prev]
  end
  def gen_do_handle_type(name, {type, subtype, params}, _) do
    [
      quote do
        defp do_handle(unquote(type), unquote(subtype), unquote(Macro.escape(params)), resolve, context) do
          unquote(name)(resolve, context)
        end
      end
    ]
  end

  def gen_supported_types_map(children, name, arity) do
    {:%{}, [], Enum.reduce(children, [], fn(handler, acc) ->
      gen_supported_types(handler, acc, name, arity)
    end)}
  end

  def gen_child(handler) do
    quote do
      unquote(gen_section(:action, handler, fn(name, section) ->
        quote do
          def unquote(name)(resolve, context) do
            unquote(compile_expr(section, handler))
          end
        end
      end))

      # unquote(gen_section(:affordance, handler, fn(name, section) ->
      #   quote do
      #     def unquote(name)(resolve, context) do
      #       unquote(compile_body(section, handler))
      #     end
      #   end
      # end))
    end
  end

  def compile_expr(section, handler) do
    {body, mod} = compile_body(section, handler)
    {:ok, exprs} = :expr.compile(body)
    quote do
      case :expr.execute(unquote(Macro.escape(exprs)), resolve, context) do
        {:ok, out, state} ->
          {:ok, unquote(mod).serialize(out), :expr.context(state)}
        error ->
          error
      end
    end
  end

  def compile_body(%{:parser => parser} = section, _handler) do
    mod = load_parser(parser || "")
    if !mod, do: raise parser <> " mediatype could not be loaded"
    case apply(mod, :parse, [section[:code], %{}]) do
      {:ok, ast} ->
        {ast, mod}
      {:error, error} ->
        raise error
    end
  end

  def compile_body(_section, _handler) do
    raise "Missing parser for section"
  end

  def load_parser(name) do
    type = Enum.find([name, "mazurka_mediatype_" <> name], fn(p) ->
      Code.ensure_loaded?(String.to_atom(p))
    end)
    type && String.to_atom(type)
  end

  def gen_supported_types(handler, acc, name, arity) do
    acc ++ Enum.map(handler[:types], fn(type) ->
      name = gen_name(handler, name)
      fun = quote do: &unquote({name, [], Elixir})/unquote(arity)
      {:ok, [res]} = expand_type(type)
      {Macro.escape(res), fun}
    end)
  end

  def expand_type(type) do
    :mimetype_parser.parse(type)
  end

  def gen_name(handler, add) when is_atom(add) do
    gen_name(handler, :erlang.list_to_binary(:erlang.atom_to_list(add)))
  end
  def gen_name(handler, add) do
    [type | _] = handler[:types]
    String.to_atom(Regex.replace(~r/[^a-zA-Z0-9]/, type, "_") <> "_" <> add)
  end

  def gen_section(name, handler, body) do
    sections = handler[:children] || []
    section = Enum.find(sections, fn (s) ->
      s[:name] == name
    end) || %{}
    docs = (section[:docs] || "") <> "\n## Code\n\n\`\`\`" <> (section[:code] || "") <> "\`\`\`"
    quote do
      @doc unquote(docs)
      unquote(body.(gen_name(handler, name), section))
    end
  end
end

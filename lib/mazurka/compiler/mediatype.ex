defmodule Mazurka.Compiler.Mediatype do
  alias Mazurka.Compiler
  alias Compiler.Lifecycle

  def compile(mediatype_module, globals, env, opts) do
    module = env.module
    etude = module
    |> Module.get_attribute(mediatype_module)
    |> Enum.map(&(Lifecycle.format(&1, globals, mediatype_module)))
    |> defaults(mediatype_module, globals, env, opts)
    |> Enum.map(fn({name, children}) ->
      {name, children
      |> Compiler.Etude.elixir_to_etude(env)
      |> unwrap_block}
    end)

    etude_module = Module.concat([module, Etude])

    {:ok, _, _, beam} = Etude.compile(etude_module, etude)

    "#{Mix.Project.compile_path}/#{etude_module}.beam"
    |> File.write!(beam)

    types = mediatype_module.content_types([])
    |> Enum.map(&(handle(&1, module, etude_module)))

    if opts.first do
      types ++ [handle({"*", "*", %{}}, module, etude_module)]
    else
      types
    end
  end

  defp defaults(sections, mediatype_module, globals, env, _opts) do
    resource = env.module
    {_, affordance} = %Mazurka.Resource.Affordance{resource: resource}
    |> Lifecycle.format(globals, mediatype_module)
    sections
    |> Keyword.put_new(:affordance, affordance)
  end

  defp handle({type, subtype, params}, module, etude_module) do
    params = Macro.escape(params)
    quote do
      defp handle(unquote(type) = type, unquote(subtype) = subtype, unquote(params) = params, context, resolve) do
        context = Mazurka.Runtime.put_mediatype(context, {type, subtype, params})
        Logger.debug("handling request with #{type}/#{subtype} in #{unquote(module)}")
        unquote(etude_module).action(context, resolve)
      end

      defp affordance(unquote(type), unquote(subtype), unquote(params), context, resolve, req, scope, props) do
        unquote(etude_module).affordance_partial(context, resolve, req, scope, props)
      end
    end
  end

  defp unwrap_block(%Etude.Node.Block{children: children}) when is_list(children) do
    children
  end
  defp unwrap_block(%Etude.Node.Block{children: children}) do
    [children]
  end
  defp unwrap_block(nil) do
    []
  end
  defp unwrap_block(children) when is_list(children) do
    children
  end
end
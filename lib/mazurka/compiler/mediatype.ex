defmodule Mazurka.Compiler.Mediatype do
  def compile(module, globals, env) do
    attrs = Module.get_attribute(env.module, module)
    |> Enum.map(&(Mazurka.Compiler.Lifecycle.format(&1, globals)))
    |> to_etude(env)
    |> IO.inspect
    nil
  end

  defp to_etude(nodes, env) do
    nodes
    # |> Enum.map(&({&1.__struct__, [{:block, (&1).block}]}))
    |> Mazurka.Compiler.Etude.elixir_to_etude(env)
    # |> Enum.map(fn({struct, props}) ->
    #   struct(struct, props)
    # end)
  end
end
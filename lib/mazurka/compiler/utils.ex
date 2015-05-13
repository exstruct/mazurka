defmodule Mazurka.Compiler.Utils do
  # this is a pretty nasty hack since elixir can't just compile something without loading it
  def quoted_to_beam(ast, src) do
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
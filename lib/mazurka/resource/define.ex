defmodule Mazurka.Resource.Define do
  defmacro mz_def(_, _) do
    nil
  end

  defmacro mz_defp(name, block) do
    IO.inspect defp_format(name, block)
  end

  defp defp_format(name, block) when is_atom(name) do
    defp_format({name, nil, []}, block)
  end
  defp defp_format(name, [do: block]) do
    defp_format(name, block)
  end
  defp defp_format({name, _meta, args}, block) do
    ## TODO
    quote do
      defp unquote(name)(unquote_splicing(args)) do
        unquote(block)
      end
    end
  end
end
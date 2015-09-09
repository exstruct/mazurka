defmodule Mazurka.Resource.Mediatype.UndefinedMediatype do
  defexception [:mediatype]

  def message(%{mediatype: mediatype}) do
    "undefined mediatype #{mediatype}"
  end
end

defmodule Mazurka.Resource.Mediatype do
  alias Mazurka.Compiler.Utils

  defmacro mediatype(module, [do: block]) do
    name = Utils.eval(module, __CALLER__)
    name = [name, Module.concat(Mazurka.Mediatype, name)] |> resolve_mediatype(name)
    Utils.register(name, __MODULE__, true, nil)
    wrap(block, name)
  end

  defp wrap({:__block__, children}, module) do
    wrap({:__block__, [], children}, module)
  end
  defp wrap({:__block__, meta, children}, module) do
    {:__block__, meta, [pre(module, meta), default_error | children] ++ [post(module, meta)]}
  end
  defp wrap(child, module) do
    {:__block__, [], [pre(module), default_error, child, post(module)]}
  end

  defp pre(module, meta \\ []) do
    {:import, meta, [module, [warn: false]]}
  end

  defp post(module, meta \\ []) do
    {:import, meta, [module, [only: [], warn: false]]}
  end

  defp resolve_mediatype([], module) do
    raise __MODULE__.UndefinedMediatype, mediatype: to_string(module)
  end
  defp resolve_mediatype([mod | rest], module) do
    mod.module_info() && mod
  catch
    _, _ ->
      resolve_mediatype(rest, module)
  end

  def default_error do
    quote do
      error error(_) do
        nil
      end
    end
  end
end

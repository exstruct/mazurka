defmodule Mazurka.Resource.Test.Case do
  def init(env) do
    Module.register_attribute(env.module, :tag, accumulate: true)
    Module.register_attribute(env.module, :moduletag, accumulate: true)
  end

  def get_tags(env) do
    mod  = env.module
    tags = Module.get_attribute(mod, :tag) ++ Module.get_attribute(mod, :moduletag)

    Module.delete_attribute(mod, :tag)

    tags |> normalize_tags
  end

  defp normalize_tags(tags) do
    tags
    |> Enum.reverse()
    |> Enum.reduce(%{}, fn
      (tag, acc) when is_atom(tag) ->
        Map.put(acc, tag, true)
      (tag, acc) when is_list(tag) ->
        Dict.merge(acc, tag)
    end)
  end
end

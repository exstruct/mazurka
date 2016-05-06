defmodule Mazurka.Resource.Utils.Scope do
  @moduledoc false

  alias Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      defp mazurka__scope(unquote(Utils.mediatype), unquote_splicing(Utils.arguments)) do
        %{}
      end
      defoverridable mazurka__scope: unquote(length(Utils.arguments) + 1)
    end
  end

  def define(var, {name, _, _}, block) when is_atom(name) do
    define(var, name, block)
  end
  def define(var, name, block) when is_atom(name) do
    bin_name = to_string(name)
    block = replace_value(var, bin_name, block)
    compile(name, block)
  end

  defp replace_value(var, name, []) do
    var_get(var, name)
  end
  defp replace_value(var, name, [do: block]) do
    replace_value(var, name, block)
  end
  defp replace_value(var, name, block) do
    params_get = var_get(var, name)
    Mazurka.Utils.postwalk(block, fn
      ({:&, _, [{:value, _, _}]}) ->
        params_get
      (other) ->
        other
    end)
  end

  defp var_get(var, name) do
    quote do
      unquote(var)[unquote(name)]
    end
  end

  def compile(name, block) do
    body = Macro.escape(get(name))

    quote do
      defmacrop unquote(name)() do
        unquote(body)
      end

      defp mazurka__scope(unquote(Utils.mediatype), unquote_splicing(Utils.arguments)) do
        unquote(Utils.scope) = super(unquote(Utils.mediatype), unquote_splicing(Utils.arguments))
        Map.put(unquote(Utils.scope), unquote(name), unquote(block))
      end
      defoverridable mazurka__scope: unquote(length(Utils.arguments) + 1)
    end
  end

  defp get(name) do
    quote do
      case Map.fetch(unquote(Utils.scope), unquote(name)) do
        :error ->
          raise RuntimeError, message: "variable #{inspect(unquote(name))} was not set before trying to use it"
        {:ok, value} ->
          value
      end
    end
  end
end

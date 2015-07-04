defmodule Mazurka.Resource.Mediatype do
  alias Mazurka.Compiler.Utils

  defmacro mediatype(module, [do: block]) do
    name = Utils.eval(module, __CALLER__)
    Utils.register(name, __MODULE__, true, nil)
    wrap(block, module)
  end

  defp wrap({:__block__, children}, module) do
    req = {:import, [], [module]}
    {:__block__, [req, default_error | children]}
  end
  defp wrap(child, module) do
    req = {:import, [], [module]}
    {:__block__, [req, default_error, child]}
  end

  def default_error do
    quote do
      error error(_) do
        nil
      end
    end
  end
end
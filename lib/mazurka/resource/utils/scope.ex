defmodule Mazurka.Resource.Utils.Scope do
  @moduledoc false

  alias Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      @mazurka_scope []
      def __mazurka_scope__(unquote(Utils.mediatype), unquote_splicing(Utils.arguments)) do
        %{}
      end
      defoverridable __mazurka_scope__: unquote(length(Utils.arguments) + 1)
    end
  end

  def define(var, name, block, type \\ :binary)
  def define(var, {name, _, _}, block, type) when is_atom(name) do
    define(var, name, block, type)
  end
  def define(var, name, block, :binary) when is_atom(name) do
    bin_name = to_string(name)
    block = transform_value(var, bin_name, block)
    compile(name, block)
  end
  def define(var, name, block, :atom) when is_atom(name) do
    block = transform_value(var, name, block)
    compile(name, block)
  end

  defp transform_value(var, name, []) do
    var_get(var, name)
  end
  defp transform_value(var, name, fun) do
    quote do
      (unquote(fun)).(unquote(var_get(var, name)))
    end
  end

  defp var_get(var, name) do
    quote do
      unquote(var)[unquote(name)]
    end
  end

  def compile(name, block) do
    quote do
      def __mazurka_scope__(unquote(Utils.mediatype), unquote_splicing(Utils.arguments)) do
        unquote(Utils.scope) = super(unquote(Utils.mediatype), unquote_splicing(Utils.arguments))
        var!(conn) = unquote(Utils.conn)
        _ = var!(conn)
        unquote(__MODULE__).dump()
        Map.put(unquote(Utils.scope), unquote(name), unquote(block))
      end
      defoverridable __mazurka_scope__: unquote(length(Utils.arguments) + 1)

      @mazurka_scope :ordsets.add_element(unquote(name), @mazurka_scope)
    end
  end

  defmacro dump() do
    scope = Module.get_attribute(__CALLER__.module, :mazurka_scope)
    vars = Enum.map(scope, &{&1, Macro.var(&1, nil)})
    assigns = Enum.map(scope, &quote(do: _ = unquote(Macro.var(&1, nil))))
    quote do
      %{unquote_splicing(vars)} = unquote(Utils.scope)
      unquote_splicing(assigns)
    end
  end
end

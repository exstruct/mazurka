defmodule Mazurka.Resource.Utils.Scope do
  @moduledoc false

  alias Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :mazurka_scope, accumulate: true)
      @before_compile unquote(__MODULE__)
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

  defmacro __before_compile__(env) do
    scope = Module.get_attribute(env.module, :mazurka_scope) |> :lists.reverse()
    values = Enum.flat_map(scope, fn({name, code}) ->
      var = Macro.var(name, nil)
      quote do
        unquote(var) = unquote(code)
        _ = unquote(var)
      end
      |> elem(2)
    end)
    map = Enum.map(scope, fn({n, _}) -> Macro.var(n, nil) end)
    quote do
      defp __mazurka_scope__(unquote(Utils.mediatype), unquote_splicing(Utils.arguments)) do
        var!(conn) = unquote(Utils.conn)
        _ = var!(conn)
        unquote_splicing(values)
        {unquote_splicing(map)}
      end
    end
  end

  def compile(name, block) do
    quote do
      @mazurka_scope {unquote(name), unquote(Macro.escape(block))}
    end
  end

  defmacro dump() do
    scope = Module.get_attribute(__CALLER__.module, :mazurka_scope) |> :lists.reverse()
    vars = Enum.map(scope, fn({n, _}) -> Macro.var(n, nil) end)
    assigns = Enum.map(scope, fn({n, _}) -> quote(do: _ = unquote(Macro.var(n, nil))) end)
    quote do
      {unquote_splicing(vars)} = unquote(Utils.scope)
      unquote_splicing(assigns)
    end
  end
end

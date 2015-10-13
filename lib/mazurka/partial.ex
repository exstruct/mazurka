defmodule Mazurka.Partial do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro defpartial({name, _, _}, [do: content]) do
    quote do
      def unquote("#{name}_partial" |> String.to_atom)(unquote_splicing(args)) do
        unquote_splicing(Mazurka.Compiler.Kernel.imports)
        unquote(__MODULE__).__exec__(unquote(name), unquote(content))
      end
    end
  end

  defmacro __exec__(name, content) do
    parent = __CALLER__.module
    mod = [parent, "Etude" <> to_string(:erlang.phash2({name, content}))] |> Module.concat()

    content
    |> Mazurka.Compiler.Utils.expand(__CALLER__)
    |> name_fun()
    |> Mazurka.Compiler.Etude.elixir_to_etude(parent)
    |> Mazurka.Compiler.compile_etude(mod, __CALLER__)

    quote do
      unquote(mod).exec_partial(unquote_splicing(args))
    end
  end

  defp args do
    [:state__, :resolve__, :req__, :scope__, :props__]
    |> Enum.map(&(Macro.var(&1, nil)))
  end

  defp name_fun(content) do
    [exec: quote do
      res = unquote(content)
      res
    end]
  end
end

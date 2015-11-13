defmodule Mazurka.Partial do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      unquote_splicing(Mazurka.Compiler.Kernel.imports)
    end
  end

  defmacro defpartial(name, [do: content]) do
    quote bind_quoted: [
      name: Macro.escape(name, unquote: true),
      content: Macro.escape(content, unquote: true)
    ] do
      name = case name do
        {direct, _, _} -> direct
        _ -> name
      end

      def unquote(name)(unquote_splicing(Mazurka.Partial.args)) do
        Mazurka.Partial.__exec__(name, unquote(content))
      end
      # BACKWARD COMPATIBILITY WITH MARKDOWN
      def unquote(:"#{name}_partial")(unquote_splicing(Mazurka.Partial.args)) do
        unquote(name)(unquote_splicing(Mazurka.Partial.args))
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

  def args do
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

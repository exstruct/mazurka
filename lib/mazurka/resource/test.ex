defmodule Mazurka.Resource.Test do
  defmacro test(name, [do: block]) do
    meta = %{file: __CALLER__.file,
             line: __CALLER__.line}
    Mazurka.Compiler.Utils.register(__MODULE__, {name, block}, meta)
  end

  defmacro request([do: block]) do
    if Mix.env == :test do
      quote do
        require Mazurka.Protocol.Request
        conn = Mazurka.Protocol.Request.request __MODULE__ do
          import Mazurka.Protocol.Request
          unquote(block)
        end
        var!(__router__).request_call(conn, [])
      end
    end
  end

  def compile(_, _) do
    nil
  end

  def compile_global(tests, env) do
    do_compile(tests, env, Mix.env)
  end

  defp do_compile(_tests, _env, :dev) do
    quote do
      @doc false
      defmacro tests(_) do
        nil
      end
    end
  end
  defp do_compile(tests, env, _) do
    module = env.module

    definitions = Enum.map(tests, fn({{name, block}, _meta}) ->
      quote do
        def unquote(:"test #{name}")({_, var!(__router__)}, _) do
          import Kernel
          import Mazurka.Compiler.Kernel, only: []
          import Mazurka.Resource.Test
          import ExUnit.Assertions
          unquote(block)
        end
      end
    end)

    tests = Enum.map(tests, fn({{name, _}, meta}) ->
      {name, meta}
    end)

    quote do
      @doc false
      defmacro tests(router) do
        router = Mazurka.Compiler.Utils.eval(router, __CALLER__)
        Mazurka.Resource.Test.register_tests(router, unquote(module), unquote(Macro.escape(tests)))
      end

      unquote_splicing(definitions)

      @doc false
      def __ex_unit__(router, pass, context) do
        {:ok, context}
      end
    end
  end

  def register_tests(router, module, tests) do
    cases = Enum.map(tests, fn({name, meta}) ->
      meta = Macro.escape(meta)
      quote bind_quoted: [module: module, router: router, name: name, meta: meta] do
        Mazurka.Resource.Test.Case.test module, router, name, meta
      end
    end)

    test_ast = quote do
      require Mazurka.Resource.Test.Case
      unquote_splicing(cases)
    end

    Module.register_attribute(router, :mazurka_test, accumulate: true)
    Module.put_attribute(router, :mazurka_test, test_ast)

    nil
  end

  def get_tests(module) do
    Module.get_attribute(module, :mazurka_test)
  end

  defmodule Case do
    defmacro test(source, router, message, meta, var \\ quote(do: _)) do
      var      = Macro.escape(var)

      quote bind_quoted: binding do
        test = :"test #{message}"
        Mazurka.Resource.Test.Case.__on_definition__(__ENV__, test, source, router, meta)
      end
    end

    def __on_definition__(env, name, source, router, additional_tags) do
      mod  = env.module
      tags = Module.get_attribute(mod, :tag) ++ Module.get_attribute(mod, :moduletag)
      tags = tags |> normalize_tags |> Dict.merge(additional_tags)

      Module.put_attribute(mod, :ex_unit_tests,
        %ExUnit.Test{name: name, case: {source, router}, tags: tags})

      Module.delete_attribute(mod, :tag)
    end

    defp normalize_tags(tags) do
      Enum.reduce Enum.reverse(tags), %{}, fn
        tag, acc when is_atom(tag) -> Map.put(acc, tag, true)
        tag, acc when is_list(tag) -> Dict.merge(acc, tag)
      end
    end
  end
end

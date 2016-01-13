defmodule Mazurka.Protocol.HTTP.Router.Tests do
  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :__mazurka_test__, accumulate: true)
    end
  end

  defmacro register_tests(module) do
    if enabled? do
      quote bind_quoted: binding do
        if :erlang.function_exported(module, :__mazurka_test__, 0) do
          for test <- module.__mazurka_test__() do
            Module.put_attribute(__MODULE__, :__mazurka_test__, test)
          end
        end
      end
    end
  end

  defmacro __before_compile__(env) do
    if enabled? do
      env.module
      |> compile_tests()
      |> Macro.escape()
      |> wrap_tests()
    end
  end

  defp enabled? do
    Mix.env == :test
  end

  defp wrap_tests(tests) do
    quote do
      defmodule Tests do
        defmacro __using__(_) do
          t = unquote(tests)
          quote do
            @ex_unit_test_names %{}
            unquote_splicing(t)

            def __ex_unit__(phase, test, _) do
              __ex_unit__(phase, test)
            end
          end
        end
      end
    end
  end

  defp compile_tests(module) do
    module
    |> Module.get_attribute(:__mazurka_test__)
    |> Enum.map(&compile_test(&1, module))
  end

  defp compile_test({module, name, tags, env}, router) do
    tags     = Macro.escape(tags)
    env      = Macro.escape(env)
    contents = Macro.escape(compile_test_body(module, name, router), unquote: true)

    quote bind_quoted: binding do
      test = :"test #{name} (#{inspect(module)})"
      Mazurka.Protocol.HTTP.Router.Tests.__on_definition__(__MODULE__, env, test, tags)
      def unquote(test)(_, _), do: unquote(contents)
    end
  end

  defp compile_test_body(module, name, router) do
    quote do
      {_variables, seed, conn, assertions} = unquote(module).__mazurka_test__(unquote(name), unquote(router))
      context = seed.(%{})

      context
      |> conn.()
      |> unquote(router).call([])
      |> Mazurka.Protocol.Request.merge_resp()
      |> assertions.(context)
    end
  end

  def __on_definition__(parent, env, name, tags \\ []) do
    mod = env.module

    moduletag = Module.get_attribute(parent, :moduletag)

    unless moduletag do
      raise "cannot define test. Please make sure you have invoked " <>
            "\"use ExUnit.Case\" in the current module"
    end

    ## TODO merge in module tag
    tags =
      (tags)
      |> Map.merge(%{line: env.line, file: env.file})

    test = %ExUnit.Test{name: name, case: {parent, mod}, tags: tags}
    test_names = Module.get_attribute(parent, :ex_unit_test_names)

    unless Map.has_key?(test_names, name) do
      Module.put_attribute(parent, :ex_unit_tests, test)
      Module.put_attribute(parent, :ex_unit_test_names, Map.put(test_names, name, true))
    end
  end
end

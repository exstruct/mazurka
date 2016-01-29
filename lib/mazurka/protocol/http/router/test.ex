defmodule Mazurka.Protocol.HTTP.Router.Tests do
  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :__mazurka_test__, accumulate: true)
    end
  end

  def register_tests(module, router) when is_atom(module) do
    module
    |> register_tests(module, router)
  end
  def register_tests(info, router) when is_tuple(info) do
    info
    |> elem(0)
    |> register_tests(info, router)
  end
  defp register_tests(module, info, router) when is_atom(module) do
    if enabled? do
      Code.ensure_loaded?(module)
      if function_exported?(module, :__mazurka_test__, 0) do
        for test <- module.__mazurka_test__() do
          Module.put_attribute(router, :__mazurka_test__, {test, info})
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
    Mazurka.Utils.env == :test
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

  defp compile_tests(router) do
    router
    |> Module.get_attribute(:__mazurka_test__)
    |> Enum.map(&compile_test(&1, router))
  end

  defp compile_test({{module, name, tags, env}, resource}, router) do
    tags     = Macro.escape(tags)
    env      = Macro.escape(env)
    contents = Macro.escape(compile_test_body(module, name, router, resource), unquote: true)

    quote bind_quoted: binding do
      test = :"#{inspect(resource)}: test #{name}"
      Mazurka.Protocol.HTTP.Router.Tests.__on_definition__(__MODULE__, env, test, tags)
      def unquote(test)(_), do: unquote(contents)
    end
  end

  def __on_definition__(parent, env, name, tags \\ []) do
    moduletag = Module.get_attribute(parent, :moduletag)

    unless moduletag do
      raise "cannot define test. Please make sure you have invoked " <>
            "\"use ExUnit.Case\" in the current module"
    end

    ## TODO merge in module tag
    tags =
      (tags)
      |> Map.merge(%{line: env.line, file: env.file})

    test = %ExUnit.Test{name: name, case: parent, tags: tags}
    test_names = Module.get_attribute(parent, :ex_unit_test_names)

    unless Map.has_key?(test_names, name) do
      Module.put_attribute(parent, :ex_unit_tests, test)
      Module.put_attribute(parent, :ex_unit_test_names, Map.put(test_names, name, true))
    end
  end

  defp compile_test_body(module, name, router, resource) do
    quote bind_quoted: binding do
      Mazurka.Protocol.HTTP.Router.Tests.__exec__(module, name, router, resource)
    end
  end

  def __exec__(module, name, router, resource) do
    {:ok, required_params, resource_params} = router.params(resource)
    required_params_map = Enum.reduce(required_params, %{}, &Map.put(&2, &1, nil))
    {_variables, seed, conn, assertions} = module.__mazurka_test__(name, resource, resource_params, required_params_map, router)
    context = seed.(%{})

    context
    |> conn.()
    |> resolve_route(router, resource, required_params)
    |> router.call(router.init([]))
    |> Mazurka.Protocol.Request.merge_resp()
    |> assertions.(context)
  end

  defp resolve_route(%{path_info: nil, private: private} = conn, router, resource, required_params) do
    params = Map.get(private, :mazurka_params, %{})

    case router.resolve(resource, params) do
      {:ok, method, path_info, _resource_params} ->
        path = "/" <> Enum.join(path_info, "/")
        %{conn | method: method, request_path: path, path_info: path_info}
      {:error, :not_found} ->
        missing_params = required_params -- Map.keys(params)
        ExUnit.Assertions.flunk("""
        Missing required parameters for #{inspect(resource)}:
          expected: #{inspect(missing_params)}
            actual: #{inspect(params)}
        """)
    end
  end
  defp resolve_route(conn, _, _, _) do
    conn
  end
end

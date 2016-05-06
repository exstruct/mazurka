defmodule Test.Mazurka.Case do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case
      import unquote(__MODULE__)
    end
  end

  defmacro context(name, [do: body, after: tests]) do
    {name, _} = Code.eval_quoted(name)
    cname = Module.concat([__CALLER__.module, name])
    quote location: :keep do
      defmodule unquote(cname) do
        Module.register_attribute(__MODULE__, :aliases, accumulate: true)
        unquote(body)
        @before_compile Test.Mazurka.Case
      end
      unquote(for {:->, _, [[test_name | args], body]} <- tests do
        quote do
          test unquote_splicing(["#{test_name} | #{inspect(name)}" | args]) do
            use unquote(cname)
            unquote(body)
            true
          end
        end
      end)
    end
  end

  defmacro resource(name, [do: body]) do
    quote location: :keep do
      defmodule unquote(name) do
        use Mazurka.Resource
        unquote(body)
      end

      @aliases unquote(name)
    end
  end

  defmacro router(name, [do: body]) do
    quote location: :keep do
      defmodule unquote(name) do
        unquote(body)
        def resolve(_, _, _) do
          throw :undefined_route
        end
      end

      @aliases unquote(name)
    end
  end

  defmacro route(method, path, resource) do
    quote location: :keep do
      def resolve(%{resource: unquote(resource), params: params} = affordance, _source, _conn) do
        %{affordance |
          method: unquote(method),
          path: "/" <> Enum.join(Enum.map(unquote(path), fn
            (param) when is_atom(param) ->
              Map.get(params, to_string(param))
            (part) ->
              part
          end), "/"),
          query: case URI.encode_query(affordance.input) do
                   "" -> nil
                   other -> other
                 end,
          fragment: affordance.opts[:fragment]
        }
      end
    end
  end

  defmacro __before_compile__(_) do
    quote do
      defmacro __using__(_) do
        for alias <- @aliases do
          {:alias, [warn: false], [alias]}
        end
        ++ for alias <- @aliases do
          ## so we don't get unused alias warnings
          {:__aliases__, [], [Module.split(alias) |> List.last |> String.to_atom()]}
        end
      end
    end
  end
end

ExUnit.start()

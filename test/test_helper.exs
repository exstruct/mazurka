defmodule Test.Mazurka.Case do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case
      import unquote(__MODULE__), except: [defmodule: 2]
      @test_idx 0
    end
  end

  defmacro context(name, [do: body, after: tests]) do
    {name, _} = Code.eval_quoted(name)
    cname = Module.concat([__CALLER__.module, name])
    tests = tests
    |> Enum.map(fn({:->, _, [[test_name | args], body]}) ->
      [test_name | test_doc] = String.split(test_name, "\n")

      {test_name, Enum.join(test_doc, "\n"), args, body}
    end)

    quote location: :keep do
      idx = @test_idx
      @test_idx @test_idx + 1
      Kernel.defmodule unquote(cname) do
        @test_idx idx
        @example true
        @contextdoc ""
        Module.register_attribute(__MODULE__, :aliases, accumulate: true)
        Module.register_attribute(__MODULE__, :doc_parts, accumulate: true)
        @assertions unquote(
          for {n, d, _, b} <- tests do
            [
              "## ", n, "\n\n",
              String.trim("#{d}"),
              "\n```elixir\n",
              ast_to_string(b),
              "\n```",
              "\n\n"
            ]
          end
        )
        import unquote(__MODULE__)
        import Kernel, except: [defmodule: 2]
        unquote(body)
        @before_compile Test.Mazurka.Case
      end
      unquote(for {test_name, _test_doc, args, body} <- tests do
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

  defmacro defmodule(name, [do: body]) do
    quote location: :keep do
      import Kernel
      import unquote(__MODULE__), except: [defmodule: 2]
      Kernel.defmodule unquote(name), unquote([do: body])
      import unquote(__MODULE__)
      import Kernel, except: [defmodule: 2]

      module_name = unquote(name) |> Module.split() |> List.last()
      @doc_parts {Module.concat([module_name]), unquote(ast_to_string(body, "  ", "\n\n"))}

      @aliases unquote(name)
    end
  end

  defp ast_to_string(ast, prefix \\ <<>>, block_join \\ <<"\n">>)
  defp ast_to_string({:assert, _, [assertion]}, prefix, block_join) do
    ast_to_string(assertion, prefix, block_join)
  end
  defp ast_to_string({:__block__, _, block}, prefix, block_join) do
    block
    |> Stream.map(&ast_to_string(&1, prefix, block_join))
    |> Enum.join(block_join)
  end
  defp ast_to_string(ast, prefix, _) do
    ast
    |> Macro.to_string()
    |> String.split("\n")
    |> Stream.map(&(prefix <> &1))
    |> Enum.join("\n")
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

  defmacro comment(comment) do
    quote do
      @doc_parts unquote(comment)
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
      doc = @doc_parts
      |> :lists.reverse()
      |> Stream.map(fn
        ({name, contents}) ->
          [
            "```elixir\n",
            "defmodule ", inspect(name), " do\n",
            contents,
            "\nend\n",
            "```"
          ]
        (comment) when is_binary(comment) ->
          comment |> String.trim()
      end)
      |> Enum.join("\n\n")

      if @example do
        [_Test, _Mazurka, _Resource, group, name] = Module.split(__MODULE__)
        path = Path.join([
          "testdoc",
          "example-#{Macro.underscore(group)}-#{@test_idx}.md"
        ])
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, [
          "# ", group, " - ", name, "\n\n",
          String.trim(@contextdoc),
          "\n\n## Setup\n\n",
          doc,
          "\n\n",
          @assertions
        ])
      end

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

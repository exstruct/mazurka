defmodule Test.Mazurka.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import ExUnit.Case, only: [test: 1]
      import Kernel, except: [defmodule: 2]
      import unquote(__MODULE__)
      @section nil
      @section_prefix "## "
      @test_prefix "#### "
      @doc_output String.replace(__ENV__.file, ".exs", ".md")
      Module.register_attribute(__MODULE__, :blocks, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro describe(name, do: body) do
    Module.put_attribute(__CALLER__.module, :section, name)

    quote do
      @blocks "\n#{@section_prefix}#{unquote(name)}"
      import Kernel, except: [defmodule: 2]
      import unquote(__MODULE__)
      ExUnit.Case.describe(unquote(name), unquote(do: body))
      import Kernel, except: [defmodule: 2]
      import unquote(__MODULE__)
    end
  end

  defmacro test(message, var \\ quote(do: _), do: body) do
    code = format_code(body, __CALLER__)
    name = message |> String.split("\n") |> hd()

    quote do
      @blocks "\n#{@test_prefix}#{unquote(message)}"
      @blocks unquote("```elixir\n#{code}\n```")
      ExUnit.Case.test(unquote(name), unquote(var), unquote(do: body))
    end
  end

  defmacro defmodule(name, do: body) do
    %{module: root} = __CALLER__
    {name, _} = Code.eval_quoted(name, [], __CALLER__)
    section = Module.get_attribute(root, :section)
    full = Module.concat([root, section, name])
    code = format_code({:defmodule, [], [name, [do: body]]}, __CALLER__)

    quote do
      @blocks unquote("```elixir\n#{code}\n```")
      alias unquote(full)
      import Kernel
      import unquote(__MODULE__), only: []
      Kernel.defmodule(unquote(full), unquote(do: body))
      import Kernel, except: [defmodule: 2]
      import unquote(__MODULE__)
    end
  end

  defmacro block(comment) do
    quote do
      @blocks "\n" <> unquote(comment)
    end
  end

  if Code.ensure_compiled?(Code.Formatter) do
    defp format_code(ast, caller) do
      ast
      |> Macro.to_string()
      |> Code.Formatter.to_algebra!(file: caller.file, line: caller.line)
      |> Inspect.Algebra.format(80)
    end
  else
    defp format_code(ast, caller) do
      ast
      |> Macro.to_string()
    end
  end

  defmacro __before_compile__(_) do
    quote do
      output = @doc_output

      case @blocks do
        [_ | _] = blocks when output !== nil ->
          data =
            blocks
            |> :lists.reverse()
            |> Enum.intersperse("\n")

          File.write!(output, data)

        _ ->
          :ok
      end
    end
  end
end

ExUnit.start()

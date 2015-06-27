defmodule Mazurka.Resource do
  @doc """
  Initialize a module as a mazurka resource

      defmodule My.Resource do
        use Mazurka.Resource
      end
  """
  defmacro __using__(_opts) do
    quote do
      import Mazurka.Resource
      import Mazurka.Resource.Action
      import Mazurka.Resource.Affordance
      import Mazurka.Resource.Conditions
      import Mazurka.Resource.Define
      import Mazurka.Resource.Error
      import Mazurka.Resource.Scope
    end
  end

  @doc """
  Define a mediatype handler block

      mediatype do
        ...
      end
  """
  defmacro mediatype(block) do
    compile_block(block, nil)
  end

  @doc """
  Define a mediatype handler block, overriding the default acceptable mediatypes

  ## Single:

      mediatype "hyper+json" do
        ...
      end

  ## Multiple

      mediatype ["hyper+json", "json"] do
        ...
      end
  """
  defmacro mediatype(types, block) do
    compile_block(block, types)
  end

  @doc false
  defp compile_block([do: block], types) do
    compile_block(block, types)
  end
  defp compile_block({:__block__, _, block}, types) do
    compile_block(block, types)
  end
  defp compile_block(block, types) do
    Enum.map(block, &handle_statement/1)
  end

  @doc false
  defp handle_statement({:@, meta, children}) do
    {:__block__, meta, Enum.map(children, fn({name, meta, expression}) ->
      {:scope, meta, [name, [do: expression]]}
    end)}
  end
  defp handle_statement({:def, meta, block}) do
    {:mz_def, meta, block}
  end
  defp handle_statement({:defp, meta, block}) do
    {:mz_defp, meta, block}
  end
  defp handle_statement(statement) do
    statement
  end
end
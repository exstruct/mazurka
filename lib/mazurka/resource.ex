defmodule Mazurka.Resource do
  alias Mazurka.Compiler.Utils

  @doc """
  Initialize a module as a mazurka resource

      defmodule My.Resource do
        use Mazurka.Resource
      end
  """
  defmacro __using__(opts) do
    Mazurka.Resource.Utils.save(__CALLER__, :mz_opts, opts)
    quote do
      import Mazurka.Resource
      import Mazurka.Resource.Condition
      import Mazurka.Resource.Error
      import Mazurka.Resource.Let
      import Mazurka.Resource.Param

      require Logger

      @before_compile {Mazurka.Compiler, :compile}
    end
  end

  @doc """
  Define a mediatype handler block

      mediatype Mazurka.Mediatype.Hyperjson do
        ...
      end
  """
  defmacro mediatype(type, block) do
    compile_block(block, type, __CALLER__)
  end

  @doc false
  defp compile_block([do: block], type, caller) do
    compile_block(block, type, caller)
  end
  defp compile_block({:__block__, _, block}, type, caller) do
    compile_block(block, type, caller)
  end
  defp compile_block(block, type, caller) when not is_list(block) do
    compile_block([block], type, caller)
  end
  defp compile_block(block, type, caller) do
    type = Utils.eval(type, caller)
    Enum.each(block, fn(child) ->
      child
      |> handle_statement(caller)
      |> handle_definition(caller, type)
    end)
    Mazurka.Resource.Utils.save(caller, :mz_mediatype, type)
  end

  @doc false
  defp handle_statement({:action, _meta, [[do: block]]}, caller) do
    block
    |> Macro.expand(caller)
    |> Mazurka.Resource.Action.handle()
  end
  defp handle_statement({:affordance, _meta, [[do: block]]}, caller) do
    block
    |> Macro.expand(caller)
    |> Mazurka.Resource.Affordance.handle(caller.module)
  end
  defp handle_statement({:def, _meta, block}, caller) do
    block
    |> Macro.expand(caller)
    |> Mazurka.Resource.Definition.handle(:def)
  end
  defp handle_statement({:defp, _meta, block}, caller) do
    block
    |> Macro.expand(caller)
    |> Mazurka.Resource.Definition.handle(:defp)
  end
  defp handle_statement({:error, _meta, block}, caller) do
    block
    |> Macro.expand(caller)
    |> Mazurka.Resource.Error.handle()
  end

  @doc false
  defp handle_definition(definition, caller, type) do
    Mazurka.Resource.Utils.save(caller, type, definition)
  end
end
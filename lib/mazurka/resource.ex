defmodule Mazurka.Resource do
  @moduledoc """
  """

  @doc """

  """
  defmacro __using__(_opts) do
    quote line: __CALLER__.line do
      use Mazurka.Resource.Action
      use Mazurka.Resource.Body
      use Mazurka.Resource.Condition
      use Mazurka.Resource.Input
      use Mazurka.Resource.Param

      # @after_compile unquote(__MODULE__)
    end
  end

  def __pop_attr__(module, name) do
    case Module.get_attribute(module, name) do
      {_line, doc} when name === :doc ->
        Module.delete_attribute(module, name)
        doc

      value ->
        Module.delete_attribute(module, name)
        value
    end
  end

  defmacro __after_compile__(%{module: module}, beam) do
    _ = module
    _ = beam
    # {:ok,{_,[{:abstract_code,{_,ac}}]}} = :beam_lib.chunks(beam,[:abstract_code])
    # :io.fwrite('~s~n', [:erl_prettypr.format(:erl_syntax.form_list(ac))])

    IO.inspect(:beam_disasm.file(beam), pretty: true, limit: :infinity)

    # seed = :os.timestamp()

    # :rand.seed(:exsplus, seed)
    # {v, _} = module.__resource__([{"application", "json", %{}}], %{}, %{})

    # v
    # |> :erts_debug.size_shared()
    # |> IO.inspect()

    # v
    # |> Poison.decode()
    # |> IO.inspect()

    # :rand.seed(:exsplus, seed)
    # {v, _} = module.__resource__([{"application", "msgpack", %{}}], %{}, %{})

    # v
    # |> :erts_debug.size_shared()
    # |> IO.inspect()

    # v
    # |> Msgpax.unpack()
    # |> IO.inspect()

    nil
  end
end

defmodule Mazurka.Resource do
  @moduledoc """
  """

  defstruct doc: nil,
            action: [],
            conditions: [],
            inputs: [],
            params: [],
            scope: [],
            value: [],
            line: nil

  @doc """

  """
  defmacro __using__(_opts) do
    quote line: __CALLER__.line do
      use Mazurka.Builder
      import Mazurka.Resource.Let, only: [let: 2]
      import Mazurka.Resource.{Action, Condition, Let, Input, Param, Map}

      @mazurka_subject %unquote(__MODULE__){
        doc: Module.get_attribute(__MODULE__, :moduledoc),
        line: __ENV__.line
      }
      # @after_compile unquote(__MODULE__)
    end
  end

  @doc false
  if Code.ensure_compiled?(Plug.Conn.WrapperError) do
    def __raise__(error, conn) do
      try do
        raise error
      rescue
        error ->
          Plug.Conn.WrapperError.reraise(conn, :error, error)
      end
    end
  else
    def __raise__(error, conn) do
      try do
        raise error
      rescue
        error ->
          Mazurka.WrapperError.reraise(conn, :error, error)
      end
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

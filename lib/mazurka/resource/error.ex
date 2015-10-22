defmodule Mazurka.Resource.Error do
  defexception [:message, :state]

  def message(%{message: message}) do
    inspect(message)
  end

  defmacro error(mediatype, name, [do: block]) do
    Mazurka.Compiler.Utils.register(mediatype, __MODULE__, block, name)
  end

  def compile(mediatype, block, globals, {_, _, [arg]}) do
    quote do
      unquote_splicing(globals[:param] || [])
      unquote_splicing(globals[:let] || [])
      unquote(arg) = prop(:error)
      error = unquote(mediatype).handle_error(unquote(block))
      ^^Mazurka.Resource.Error.set_error(error)
    end
  end

  def expand(ast, _) do
    ast
    |> Mazurka.Resource.Param.format()
    |> Mazurka.Resource.Input.format()
  end

  def format_name({name, _meta, _args}) when is_atom(name) do
    name
  end

  def set_error([message], %{private: private} = conn, _parent, _ref, _attrs) do
    private = Map.put(private, :mazurka_error, true)
    :erlang.error(__MODULE__.exception([message: message, state: %{conn | private: private}]))
  end
end

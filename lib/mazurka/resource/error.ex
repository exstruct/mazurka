defmodule Mazurka.Resource.Error do
  defstruct args: [],
            block: nil,
            name: nil

  def handle([{name, _meta, args}, [do: block]]) do
    %__MODULE__{args: args,
                block: block,
                name: name}
  end
end

defmodule Mazurka.Resource.RuntimeError do
  defexception [:message, :name]
end

defimpl Mazurka.Compiler.Lifecycle, for: Mazurka.Resource.Error do
  def format(node, globals) do
    quote do
      unquote_splicing(globals.lets)
      raise %Mazurka.Resource.RuntimeError{message: unquote(node.block),
                                           name: unquote(node.name)}
    end
  end
end
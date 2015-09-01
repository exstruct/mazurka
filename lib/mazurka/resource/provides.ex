defmodule Mazurka.Resource.Provides do
  alias Mazurka.Compiler.Utils

  defmacro provides(mediatype, type) do
    {:ok, types} = type
    |> Utils.eval(__CALLER__)
    |> to_string()
    |> :mimetype_parser.parse(type)

    for type <- types do
      Utils.register(mediatype, __MODULE__, type, nil)
    end
  end

  def format_types(nil, default) do
    default
  end
  def format_types(types, [{_, _, _, content_type} | _]) do
    for {{type, subtype, params}, _} <- types do
      {type, subtype, params, content_type}
    end
  end

  def compile(_mediatype, _ast, _globals, _meta) do
    nil
  end
end

defmodule Mazurka.UnacceptableContentTypeException do
  @moduledoc """
  TODO write the docs
  """

  defexception [:acceptable, :content_type, :conn]

  def message(%{content_type: [content_type]} = ex) do
    message(%{ex | content_type: content_type})
  end

  def message(%{content_type: content_types}) when is_list(content_types) do
    types = content_types |> Enum.map(&format_type/1) |> Enum.join(", ")
    "Unacceptable content types #{inspect(types)}"
  end

  def message(%{content_type: content_type}) do
    "Unacceptable content type #{inspect(format_type(content_type))}"
  end

  defp format_type({type, subtype, _params}) do
    # TODO add params
    "#{type}/#{subtype}"
  end
end

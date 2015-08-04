defmodule Mazurka.Runtime.Affordance do
  @moduledoc """
  Represents an affordance in a response. This is used by mediatypes to serialize the link in the appropriate
  format. It's broken into its separate parts (method, host, path, etc.) for easy manipulation.
  """

  defstruct mediatype: nil,
            method: nil,
            scheme: nil,
            host: nil,
            path: nil,
            qs: nil,
            fragment: nil
end

defimpl String.Chars, for: Mazurka.Runtime.Affordance do
  def to_string(%{fragment: fragment, host: host, path: path, port: port, query: query, scheme: scheme}) do
    %URI{fragment: format_fragment(fragment),
         host: host,
         path: path,
         port: port,
         query: query,
         scheme: scheme}
  end

  defp format_fragment(nil), do: ""
  defp format_fragment(fragment) when is_list(fragment), do: "/#{Enum.join(fragment, "/")}"
  defp format_fragment(fragment), do: fragment
end

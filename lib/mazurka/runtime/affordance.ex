defmodule Mazurka.Runtime.Affordance do
  defstruct mediatype: nil,
            props: nil,
            method: nil,
            scheme: nil,
            host: nil,
            path: nil,
            qs: nil,
            fragment: nil
end

defimpl String.Chars, for: Mazurka.Runtime.Affordance do
  def to_string(affordance) do
    "#{format_host(affordance.scheme, affordance.host)}#{
       format_path(affordance.path)}#{
       format_qs(affordance.qs)}#{
       format_fragment(affordance.fragment)}"
  end

  defp format_host(_, nil), do: ""
  defp format_host(nil, host), do: "://#{host}"
  defp format_host(scheme, host), do: "#{scheme}://#{host}"

  defp format_path(nil), do: "/"
  defp format_path([]), do: "/"
  defp format_path(path), do: "/" <> Enum.join(path, "/")

  defp format_qs(nil), do: ""
  defp format_qs(qs), do: "?#{qs}"

  defp format_fragment(nil), do: ""
  defp format_fragment(fragment), do: "##{fragment}"
end
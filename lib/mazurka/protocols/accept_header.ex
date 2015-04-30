defmodule Mazurka.Protocols.HTTP.AcceptHeader do
  def handle([]) do
    []
  end
  def handle([header|_]) do
    parse(String.split(header, ","), [])
  end

  defp parse([], acc) do
    Enum.sort(acc)
  end
  defp parse([h|t], acc) do
    case Plug.Conn.Utils.media_type(h) do
      {:ok, type, subtype, args} ->
        parse(t, [{-parse_q(args), {type, subtype, Dict.delete(args, "q")}}|acc])
      :error ->
        parse(t, acc)
    end
  end

  defp parse_q(args) do
    case Map.fetch(args, "q") do
      {:ok, float} ->
        case Float.parse(float) do
          {float, _} -> float
          :error -> 1.0
        end
      :error ->
        1.0
    end
  end
end
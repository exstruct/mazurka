defmodule Mazurka.Mediatype.Hyperjson.Hyperpath do
  defmacro __using__(_) do
    quote location: :keep do
      defmacro hyperpath(ast) do
        Mazurka.Mediatype.Hyperjson.Hyperpath.hyperpath(ast)
      end
    end
  end

  def hyperpath({{:., _, [lhs, rhs]}, _, _}) do
    rhs = to_string(rhs)
    quote location: :keep do
      parent = unquote(wrap(lhs))
      href = Dict.get(parent, "href")
      case Dict.get(parent, unquote(rhs)) do
        nil when is_binary(href) ->
          conn = request do
            import Mazurka.Protocol.HTTP.Request
            get href
            accept "hyper+json"
          end
          Dict.get(Mazurka.Format.JSON.decode(conn.resp_body), unquote(rhs))
        nil ->
          nil
        other ->
          other
      end
    end
  end
  def hyperpath(var) do
    var
  end

  defp wrap({:_, _, _}) do
    quote do
      %{"href" => "/"}
    end
  end
  defp wrap(var) do
    quote do
      unquote(hyperpath(var)) || %{}
    end
  end
end
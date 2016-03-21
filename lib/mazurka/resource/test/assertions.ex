defmodule Mazurka.Resource.Test.Assertions do
  import ExUnit.Assertions

  defmacro __using__(_) do
    quote do
      import ExUnit.Assertions
      import unquote(__MODULE__)
      var!(__parsed_body__) = nil
    end
  end

  for call <- [:assert, :refute] do
    def unquote(:"#{call}_status")(conn, status_code) do
      a = conn.status
      e = status_code
      ExUnit.Assertions.unquote(call)(a == e, [
        lhs: a,
        message: "Expected status code #{inspect(e)}, got #{inspect(a)}"])
      conn
    end

    def unquote(:"#{call}_success_status")(conn) do
      a = conn.status
      ExUnit.Assertions.unquote(call)(a < 400, [
        lhs: a,
        message: "Expected status code #{inspect(a)} to be successful (< 400)"])
      conn
    end

    def unquote(:"#{call}_error_status")(conn) do
      a = conn.status
      ExUnit.Assertions.unquote(call)(a >= 400, [
        lhs: a,
        message: "Expected status code #{inspect(a)} to be an error (>= 400)"])
      conn
    end

    def unquote(:"#{call}_body")(conn, body) do
      ExUnit.Assertions.unquote(call)(conn.resp_body == body)
      conn
    end

    def unquote(:"#{call}_body_contains")(conn, body) do
      a = conn.resp_body
      e = body

      indented = fn ->
        a
        |> String.split("\n")
        |> Enum.map(&("    " <> &1))
        |> Enum.join("\n")
      end

      ExUnit.Assertions.unquote(call)(String.contains?(a, e), [
        lhs: a,
        rhs: e,
        message: "Expected response body to contain #{inspect(e)}, got:\n#{indented.()}"])
      conn
    end

    defmacro unquote(:"#{call}_json")(conn, match) do
      call = unquote(call)
      match_code = match |> Macro.escape()
      {match, vars} = format_match(match)

      quote do
        _conn = unquote(conn)
        var!(__parsed_body__) = var!(__parsed_body__) || Poison.decode!(_conn.resp_body)

        match_code = unquote(match_code)
        unquote_splicing(vars)

        ExUnit.Assertions.unquote(call)(match?(unquote(match), var!(__parsed_body__)), [
          expr: quote do
            unquote(match_code) = unquote(Macro.escape(var!(__parsed_body__)))
          end,
          message: "Expected JSON response body to match"])
        _conn
      end
    end

    def unquote(:"#{call}_transition")(conn, location) when is_binary(location) do
      location = if location == :proplists.get_value("location", conn.resp_headers) || location =~ ~r|://| do
        location
      else
        %URI{scheme: to_string(conn.scheme || "http"), host: conn.host, port: conn.port, path: location} |> to_string()
      end

      ExUnit.Assertions.unquote(call)(:proplists.get_value("location", conn.resp_headers) == location)
      conn
    end
    def unquote(:"#{call}_transition")(conn, resource, params \\ %{}, query \\ nil, fragment \\ nil) do
      {:ok, location} = [resource, Mazurka.Resource.Link.unwrap_ids(params), Mazurka.Resource.Link.unwrap_ids(query), fragment]
      |> Mazurka.Resource.Link.resolve(conn, self(), :erlang.make_ref(), %{})

      ExUnit.Assertions.unquote(call)(:proplists.get_value("location", conn.resp_headers) == to_string(location))
      conn
    end

    def unquote(:"#{call}_invalidates")(conn, _url) do
      ## TODO
      conn
    end
  end

  defp format_match(ast) do
    ast = Mazurka.Compiler.Utils.prewalk(ast, fn
      ({call, _, _} = expr) when is_tuple(call) ->
        acc(expr)
      ({call, _, _} = expr) when not call in [:{}, :%{}, :_, :|, :^] ->
        acc(expr)
      (expr) ->
        expr
    end)
    {ast, acc()}
  end

  defp acc do
    Process.delete(:__assert_json__) || []
  end
  defp acc(expr) do
    acc = Process.get(:__assert_json__, [])
    var = Macro.var(:"_json_#{length(acc)}", __MODULE__)
    Process.put(:__assert_json__, [quote do
      unquote(var) = unquote(expr)
    end | acc])
    var
  end
end

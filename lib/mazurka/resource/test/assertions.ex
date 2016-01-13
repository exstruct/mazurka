defmodule Mazurka.Resource.Test.Assertions do
  defmacro __using__(_) do
    quote do
      import ExUnit.Assertions
      import unquote(__MODULE__)
      var!(__parsed_body__) = nil
    end
  end

  for call <- [:assert, :refute] do
    defmacro unquote(:"#{call}_status")(conn, status_code) do
      call = unquote(call)
      quote do
        a = unquote(conn).status
        e = unquote(status_code)
        ExUnit.Assertions.unquote(call)(a == e, [
          lhs: a,
          message: "Expected status code #{inspect(e)}, got #{inspect(a)}"])
        unquote(conn)
      end
    end

    defmacro unquote(:"#{call}_success_status")(conn) do
      call = unquote(call)
      quote do
        a = unquote(conn).status
        ExUnit.Assertions.unquote(call)(a < 400, [
          lhs: a,
          message: "Expected status code #{inspect(a)} to be successful (< 400)"])
        unquote(conn)
      end
    end

    defmacro unquote(:"#{call}_error_status")(conn) do
      call = unquote(call)
      quote do
        a = unquote(conn).status
        ExUnit.Assertions.unquote(call)(a >= 400, [
          lhs: a,
          message: "Expected status code #{inspect(a)} to be an error (>= 400)"])
        unquote(conn)
      end
    end

    defmacro unquote(:"#{call}_body")(conn, body) do
      call = unquote(call)
      quote do
        ExUnit.Assertions.unquote(call)(unquote(conn).resp_body == unquote(body))
        unquote(conn)
      end
    end

    defmacro unquote(:"#{call}_body_contains")(conn, body) do
      call = unquote(call)
      quote do
        a = unquote(conn).resp_body
        e = unquote(body)

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
        unquote(conn)
      end
    end

    defmacro unquote(:"#{call}_json")(conn, match) do
      call = unquote(call)
      match_code = match |> Macro.escape()
      quote do
        var!(__parsed_body__) = var!(__parsed_body__) || Poison.decode!(unquote(conn).resp_body)

        match_code = unquote(match_code)

        ExUnit.Assertions.unquote(call)(match?(unquote(match), var!(__parsed_body__)), [
          expr: quote do
            unquote(match_code) = unquote(Macro.escape(var!(__parsed_body__)))
          end,
          message: "Expected JSON response body to match"])
        unquote(conn)
      end
    end

    defmacro unquote(:"#{call}_transition")(conn, location) do
      call = unquote(call)
      quote do
        ExUnit.Assertions.unquote(call)(:proplists.get_value("location", unquote(conn).resp_headers) == unquote(location))
      end
    end

    defmacro unquote(:"#{call}_invalidates")(conn, _url) do
      # call = unquote(call)
      quote do
        # TODO
        unquote(conn)
      end
    end
  end
end

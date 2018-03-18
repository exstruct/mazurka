defmodule Mazurka.Resource.Body do
  @moduledoc false

  defstruct children: [],
            line: 0

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro body(do: body) do
    body(Macro.var(:conn, nil), body, __CALLER__)
  end

  defmacro body(conn, do: body) do
    body(conn, body, __CALLER__)
  end

  defp body(conn, body, env) do
    body =
      Mazurka.Resource.Builder.eval(
        __MODULE__,
        body,
        quote do
          import Mazurka.Resource.Let

          import Mazurka.Resource.Body.{
            AffordanceFor,
            Collection,
            Condition,
            Constant,
            Map,
            Resolve
          }
        end,
        env
      )

    quote do
      conn = unquote(conn)
      conn
    end
  end
end

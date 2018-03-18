defmodule Mazurka.Resource.Action do
  @moduledoc false

  defstruct children: [],
            line: 0

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro action(do: body) do
    action_body(Macro.var(:conn, nil), body, __CALLER__)
  end

  defmacro action(conn, do: body) do
    action_body(conn, body, __CALLER__)
  end

  defp action_body(conn, body, env) do
    action =
      Mazurka.Resource.Builder.eval(
        __MODULE__,
        body,
        quote do
          import Mazurka.Resource.Let

          import Mazurka.Resource.Action.{
            AffordanceFor,
            Collection,
            Condition,
            Constant,
            Map,
            RedirectTo,
            Resolve
          }
        end,
        env
      )

    Module.put_attribute(env.module, :mazurka_action, action)

    IO.inspect(action)

    quote do
      conn = unquote(conn)
      conn
    end
  end
end

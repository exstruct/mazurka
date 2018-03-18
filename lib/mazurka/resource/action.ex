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
    quote do
      case unquote(conn || Macro.var(:conn, nil)) do
        %{private: %{mazurka_affordance: true}} = conn ->
          conn

        conn ->
          import unquote(__MODULE__).{
            RedirectTo
          }

          unquote(body)
      end
    end
    |> maybe_assign(conn)
  end

  defp maybe_assign(body, nil) do
    quote do
      unquote(Macro.var(:conn, nil)) = unquote(body)
    end
  end

  defp maybe_assign(body, _) do
    body
  end
end

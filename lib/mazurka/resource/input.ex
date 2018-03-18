defmodule Mazurka.Resource.Input do
  @moduledoc false

  defstruct children: [],
            line: 0

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro input(do: body) do
    input_body(nil, [], body, __CALLER__)
  end

  defmacro input(opts, do: body) when is_list(opts) do
    input_body(nil, opts, body, __CALLER__)
  end

  defmacro input(conn, do: body) do
    input_body(conn, [], body, __CALLER__)
  end

  defmacro input(conn, opts, do: body) when is_list(opts) do
    input_body(conn, opts, body, __CALLER__)
  end

  def __subject__ do
    Macro.var(:"@mazurka_input", __MODULE__)
  end

  defp input_body(conn, opts, body, env) do
    input =
      Mazurka.Resource.Builder.eval(
        __MODULE__,
        body,
        quote do
          import Mazurka.Resource.Let

          import Mazurka.Resource.Input.{
            Map
          }
        end,
        env
      )

    Module.put_attribute(env.module, :mazurka_input, input)

    quote do
      unquote(conn || Macro.var(:conn, nil))
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

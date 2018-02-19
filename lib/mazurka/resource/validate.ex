defmodule Mazurka.Resource.Validate do
  @moduledoc false

  defstruct doc: nil,
            exception: nil,
            failure: nil,
            conn: nil,
            opts: nil,
            body: nil,
            value: nil,
            line: nil

  defmacro validate({:&, _, [{:/, _, [{call, meta, _}, 1]}]}) do
    value = Macro.var(:value, nil)
    body = {call, meta, [value]}
    validate_body(value, nil, nil, body)
  end

  defmacro validate({:&, _, [{:/, _, [{call, meta, _}, 2]}]}) do
    value = Macro.var(:value, nil)
    conn = Macro.var(:conn, nil)
    body = {call, meta, [value, conn]}
    validate_body(value, conn, nil, body)
  end

  defmacro validate({:&, _, [{:/, _, [{call, meta, _}, 3]}]}) do
    value = Macro.var(:value, nil)
    conn = Macro.var(:conn, nil)
    opts = Macro.var(:opts, nil)
    body = {call, meta, [value, conn, opts]}
    validate_body(value, conn, opts, body)
  end

  defmacro validate(do: body) do
    validate_body(Macro.var(:_, nil), nil, nil, body)
  end

  defmacro validate(value, do: body) do
    validate_body(value, nil, nil, body)
  end

  defmacro validate(value, conn, do: body) do
    validate_body(value, conn, nil, body)
  end

  defmacro validate(value, conn, opts, do: body) do
    validate_body(value, conn, opts, body)
  end

  defp validate_body(value, conn, opts, body) do
    quote do
      validation = %unquote(__MODULE__){
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        failure: Mazurka.Builder.get_attribute(__MODULE__, :failure),
        exception: Mazurka.Builder.get_attribute(__MODULE__, :exception),
        conn: unquote(Macro.escape(conn)),
        opts: unquote(Macro.escape(opts)),
        body: unquote(Macro.escape(body)),
        value: unquote(Macro.escape(value)),
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.append(@mazurka_subject, :validations, validation)
    end
  end

  alias Mazurka.Compiler

  defimpl Compiler.Compilable do
    def compile(
          %{
            doc: doc,
            line: line,
            exception: exception,
            failure: failure
          } = condition,
          vars,
          input
        ) do
      {ast, vars} = compile(condition, vars)
      %{conn: conn} = vars

      message =
        case doc do
          nil -> nil
          doc -> doc |> String.trim() |> String.split("\n") |> hd()
        end

      error =
        struct(
          exception || Mazurka.ValidationError,
          message: message,
          input: input,
          failure: failure
        )
        |> Map.to_list()

      ast =
        quote line: line do
          unquote(ast) || Mazurka.Resource.__raise__(%{unquote_splicing(error)}, unquote(conn))
        end

      {ast, vars}
    end

    def compile(
          %{
            conn: nil,
            opts: nil,
            value: nil,
            body: body
          },
          vars
        ) do
      {body, vars}
    end

    def compile(
          %{
            conn: conn,
            opts: opts,
            value: value,
            body: body,
            line: line
          },
          %{
            conn: v_conn,
            opts: v_opts,
            value: v_value
          } = vars
        ) do
      {Compiler.join(
         [
           quote do
             unquote(conn || Macro.var(:_, nil)) = unquote(v_conn)
             unquote(opts || Macro.var(:_, nil)) = unquote(v_opts)
             unquote(value || Macro.var(:_, nil)) = unquote(v_value)
           end,
           body
         ],
         line
       ), vars}
    end
  end
end

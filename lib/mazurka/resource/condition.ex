defmodule Mazurka.Resource.Condition do
  @moduledoc false

  defstruct doc: nil,
            exception: nil,
            conn: nil,
            opts: nil,
            body: nil,
            line: nil

  # TODO add remote/local calls
  defmacro condition(do: body) do
    condition_body(nil, nil, body)
  end

  defmacro condition(conn, do: body) do
    condition_body(conn, nil, body)
  end

  defmacro condition(conn, opts, do: body) do
    condition_body(conn, opts, body)
  end

  defp condition_body(conn, opts, body) do
    quote do
      condition = %unquote(__MODULE__){
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        exception: Mazurka.Builder.get_attribute(__MODULE__, :exception),
        conn: unquote(Macro.escape(conn)),
        opts: unquote(Macro.escape(opts)),
        body: unquote(Macro.escape(body)),
        line: __ENV__.line
      }

      @mazurka_subject Mazurka.Builder.append(@mazurka_subject, :conditions, condition)
    end
  end

  alias Mazurka.Compiler

  defimpl Compiler.Compilable do
    def compile(
          %{
            doc: doc,
            line: line,
            exception: exception
          } = condition,
          vars,
          invariant
        )
        when not is_nil(invariant) do
      {ast, vars} = compile(condition, vars, nil)
      %{conn: conn} = vars

      message =
        case doc do
          nil -> nil
          doc -> doc |> String.trim() |> String.split("\n") |> hd()
        end

      error = struct(exception || invariant, message: message) |> Map.to_list()

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
            body: body
          },
          vars,
          _
        ) do
      {body, vars}
    end

    def compile(
          %{
            conn: conn,
            opts: opts,
            body: body,
            line: line
          },
          %{
            conn: v_conn,
            opts: v_opts
          } = vars,
          _
        ) do
      {Compiler.join(
         [
           quote do
             unquote(conn) = unquote(v_conn)
             unquote(opts || Macro.var(:_, nil)) = unquote(v_opts)
           end,
           body
         ],
         line
       ), vars}
    end
  end
end

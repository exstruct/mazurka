defmodule Mazurka.Resource.Param do
  @moduledoc false

  defstruct doc: nil,
            name: nil,
            scope: [],
            validations: [],
            value: [],
            line: nil

  @params Macro.var(:"@mazurka_params", nil)

  defmacro param(name) do
    param_body(name, nil)
  end

  defmacro param(name, do: body) do
    param_body(name, body)
  end

  defp param_body({name, _, context}, body) when is_atom(context) do
    param_body(name, body)
  end

  defp param_body(name, body) do
    quote do
      prev = @mazurka_subject

      @mazurka_subject %unquote(__MODULE__){
        name: unquote(name),
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        line: __ENV__.line
      }

      import Mazurka.Resource.{Condition, Constant, Resolve, Validate}

      resolve do
        Map.fetch!(unquote(@params), unquote(name))
      end

      unquote(body)

      @mazurka_subject Mazurka.Builder.append(prev, :scope, @mazurka_subject)
    end
  end

  alias Mazurka.Compiler

  defimpl Compiler.Compilable do
    def compile(
          %@for{
            name: name,
            value: value,
            scope: scope,
            validations: validations,
            line: line
          },
          vars,
          _opts
        ) do
      {body, vars} = @protocol.compile(value, vars)

      body =
        quote line: line do
          unquote(Macro.var(name, nil)) = unquote(body)
        end

      {body, vars} = Compiler.wrap_conditions(body, vars, validations, Mazurka.ValidationError)
      {body, vars} = Compiler.wrap_scope(body, vars, scope)
      {body, vars}
    end
  end

  defimpl Compiler.Scopable do
    @params Macro.var(:"@mazurka_params", nil)

    def compile(_, %{params: @params} = vars) do
      {nil, vars}
    end

    def compile(_, %{conn: conn} = vars) do
      vars = Map.put(vars, :params, @params)

      body =
        quote do
          {unquote(@params), unquote(conn)} = Mazurka.Conn.get_params(unquote(conn))
        end

      {body, vars}
    end
  end
end

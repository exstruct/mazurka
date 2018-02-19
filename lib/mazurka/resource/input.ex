defmodule Mazurka.Resource.Input do
  @moduledoc false

  defstruct conditions: [],
            doc: nil,
            info: %{},
            name: nil,
            scope: [],
            validations: [],
            value: [],
            line: nil

  @input Macro.var(:"@mazurka_input", nil)

  defmacro input(name) do
    input_body(name, nil)
  end

  defmacro input(name, do: body) do
    input_body(name, body)
  end

  defp input_body({name, _, context}, body) when is_atom(name) and is_atom(context) do
    input_body(name, body)
  end

  defp input_body(name, body) do
    quote do
      prev = @mazurka_subject

      @mazurka_subject %unquote(__MODULE__){
        name: unquote(name),
        doc: Mazurka.Builder.get_attribute(__MODULE__, :doc),
        line: __ENV__.line
      }

      import Mazurka.Resource.{Condition, Constant, Resolve, Validate, Validation}

      resolve do
        unquote(__MODULE__).get(unquote(@input), unquote(to_string(name)), unquote(name))
      end

      unquote(body)

      %{conditions: conditions, validations: validations} = input = @mazurka_subject

      input = %{
        input
        | conditions: :lists.reverse(conditions),
          validations: :lists.reverse(validations)
      }

      @mazurka_subject Mazurka.Builder.append(prev, :scope, input)
    end
  end

  def get(map, binary, atom) do
    case Map.fetch(map, binary) do
      {:ok, value} ->
        value

      _ ->
        Map.get(map, atom)
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
      value = Macro.var(name, nil)
      vars = Map.put(vars, :value, value)

      body =
        quote line: line do
          unquote(value) = unquote(body)
        end

      {body, vars} = Compiler.wrap_scope(body, vars, scope)
      {validations, vars} = Enum.map_reduce(validations, vars, &@protocol.compile(&1, &2, name))
      vars = Map.delete(vars, :value)

      {Compiler.join(
         [
           body,
           validations
         ],
         line
       ), vars}
    end
  end

  defimpl Compiler.Scopable do
    @input Macro.var(:"@mazurka_input", nil)

    def compile(_, %{input: @input} = vars) do
      {nil, vars}
    end

    def compile(_, %{conn: conn} = vars) do
      vars = Map.put(vars, :input, @input)

      body =
        quote do
          {unquote(@input), unquote(conn)} = Mazurka.Conn.get_input(unquote(conn))
        end

      {body, vars}
    end
  end
end

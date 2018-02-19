defmodule Mazurka.Resource.Validation do
  @moduledoc false

  defmacro put_info(name, do: body) do
    put_info_body(
      name,
      quote do
        %Mazurka.Resource.Resolve{
          body: unquote(body),
          line: __ENV__.line
        }
      end
    )
  end

  defmacro put_info(name, value) do
    put_info_body(
      name,
      quote do
        %Mazurka.Resource.Constant{
          value: unquote(value),
          line: __ENV__.line
        }
      end
    )
  end

  defmacro put_info(name, conn, do: body) do
    put_info_body(
      name,
      quote do
        %Mazurka.Resource.Resolve{
          body: unquote(body),
          conn: unquote(conn),
          line: __ENV__.line
        }
      end
    )
  end

  defmacro put_info(name, conn, opts, do: body) do
    put_info_body(
      name,
      quote do
        %Mazurka.Resource.Resolve{
          body: unquote(body),
          conn: unquote(conn),
          opts: unquote(opts),
          line: __ENV__.line
        }
      end
    )
  end

  defp put_info_body(name, value) do
    quote do
      %{info: info} = @mazurka_subject
      info = Mazurka.Builder.put(info, unquote(name), unquote(value))
      @mazurka_subject %{@mazurka_subject | info: info}
    end
  end

  types = [
    is_binary: [:string, :text],
    is_boolean: [:boolean],
    is_integer: [:integer],
    is_float: [:float],
    is_number: [:number],
    is_map: [:map]
  ]

  for {guard, aliases} <- types,
      type <- aliases do
    defmacro type(type) when type in [unquote(type), unquote(to_string(type))] do
      guard = unquote(guard)
      type = unquote(type)

      quote do
        @failure unquote("should be of type #{type}")
        validate(&(Kernel.unquote(guard) / 1))
        Mazurka.Resource.Validation.put_info(:type, unquote(type))
      end
    end
  end

  defmacro type(type) do
    quote do
      raise ArgumentError, "Unsupported type: #{unquote(type)}"
    end
  end

  defmacro required do
    quote do
      @failure "is required"
      validate value do
        case value do
          nil ->
            false

          _ ->
            true
        end
      end

      Mazurka.Resource.Validation.put_info(:required, true)
    end
  end
end

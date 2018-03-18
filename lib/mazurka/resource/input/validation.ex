defmodule Mazurka.Resource.Input.Validation do
  defstruct category: nil,
            failure: nil,
            code: nil,
            line: 0

  alias Mazurka.Resource.{Builder, Input}

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

      code =
        quote do
          &(Kernel.unquote(guard) / 1)
        end

      Builder.child(
        quote do
          %unquote(__MODULE__){
            category: :type,
            failure: unquote("should be type of #{type}"),
            code: unquote(Macro.escape(code))
          }
        end
      )
    end
  end

  defmacro type(type) do
    quote do
      raise ArgumentError, "Unsupported type: #{unquote(type)}"
    end
  end

  defmacro required do
    code =
      quote do
        fn
          nil ->
            false

          _ ->
            true
        end
      end

    Builder.child(
      quote do
        %unquote(__MODULE__){
          category: :required,
          failure: "is required",
          code: unquote(Macro.escape(code))
        }
      end
    )
  end
end

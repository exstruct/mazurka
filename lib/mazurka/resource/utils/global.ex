defmodule Mazurka.Resource.Utils.Global do
  @moduledoc false

  defmacro __using__(opts) do
    var_name = opts[:var]

    quote bind_quoted: binding do
      require Mazurka.Resource.Utils

      defmacro get() do
        Mazurka.Resource.Utils.unquote(var_name)()
      end

      defmacro get(name) when is_atom(name) do
        value = Mazurka.Resource.Utils.unquote(var_name)()
        name = to_string(name)
        quote do
          unquote(value)[unquote(name)]
        end
      end
      defmacro get(name) when is_binary(name) do
        value = Mazurka.Resource.Utils.unquote(var_name)()
        quote do
          unquote(value)[unquote(name)]
        end
      end
      defmacro get(name) do
        value = Mazurka.Resource.Utils.unquote(var_name)()
        quote do
          unquote(value)[to_string(unquote(name))]
        end
      end

      defmacro get(name, fallback) do
        quote do
          case unquote(__MODULE__).get(unquote(name)) do
            nil ->
              unquote(fallback)
            value ->
              value
          end
        end
      end
    end
  end
end

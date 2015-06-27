defmodule Mazurka.Resource.Error do
  import Mazurka.Resource.Define

  defstruct response: nil

  defmacro error({name, _meta, args}, block) do
    quote do
      mz_defp unquote(name)(unquote_splicing(args)) do
        raise %Mazurka.Resource.Error{response: unquote(block)}
      end
    end
  end

  defmacro expression >>> error_fn do
    quote do
      try do
        unquote(expression)
      rescue
        err ->
          fun = &unquote(error_fn)/1
          fun.(err)
      end
    end
  end
end
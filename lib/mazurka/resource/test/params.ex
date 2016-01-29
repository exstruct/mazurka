defmodule Mazurka.Resource.Test.Params do
  defmacro __using__(_) do
    quote do
      require unquote(__MODULE__)
      alias unquote(__MODULE__)
    end
  end

  defmacro get do
    quote do
      var!(__params__)
    end
  end

  defmacro get(name) do
    quote do
      Mazurka.Runtime.get_param(var!(__params__), unquote(name))
    end
  end
end

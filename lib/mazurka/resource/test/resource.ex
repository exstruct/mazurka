defmodule Mazurka.Resource.Test.Resource do
  defmacro __using__(_) do
    quote do
      require unquote(__MODULE__)
      alias unquote(__MODULE__)
    end
  end

  defmacro self do
    quote do
      var!(__resource__)
    end
  end

  defmacro name do
    quote do
      Mazurka.Resource.Resource.get_elem(var!(__resource__), -1)
    end
  end

  defmacro param(index) do
    quote do
      Mazurka.Resource.Resource.get_elem(var!(__resource__), unquote(index))
    end
  end
end

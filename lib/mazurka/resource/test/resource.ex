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
      Mazurka.Resource.Resource.get_name(var!(__resource__))
    end
  end

  defmacro params do
    quote do
      var!(__resource_params__)
    end
  end

  defmacro param(name) do
    quote do
      Mazurka.Resource.Resource.get_param(var!(__resource_params__), unquote(name))
    end
  end
end

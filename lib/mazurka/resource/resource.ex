defmodule Mazurka.Resource.Resource do
  @doc false
  def format({{:., _, [{:__aliases__, _, [:Resource]}, :self]}, _, []}, type) do
    get(type)
  end
  def format({{:., _, [input, :self]}, _, []}, type) when input in [:Resource, Elixir.Resource, __MODULE__] do
    get(type)
  end
  def format({{:., _, [{:__aliases__, _, [:Resource]}, :name]}, _, []}, type) do
    get(type, -1)
  end
  def format({{:., _, [input, :name]}, _, []}, type) when input in [:Resource, Elixir.Resource, __MODULE__] do
    get(type, -1)
  end
  def format({{:., _, [{:__aliases__, _, [:Resource]}, :param]}, _, [index]}, type) do
    get(type, index)
  end
  def format({{:., _, [input, :param]}, _, [index]}, type) when input in [:Resource, Elixir.Resource, __MODULE__] do
    get(type, index)
  end
  def format(other, _) do
    other
  end

  defp get(:prop) do
    {:etude_prop, [], [:resource]}
  end
  defp get(:conn) do
    quote do
      ^^Mazurka.Resource.Resource.self()
    end
  end
  defp get(:prop, index) do
    quote do
      ^Mazurka.Resource.Resource.get_elem(unquote(get(:prop)), unquote(index))
    end
  end
  defp get(:conn, index) do
    quote do
      ^Mazurka.Resource.Resource.get_elem(unquote(get(:conn)), unquote(index))
    end
  end

  @doc false
  def self([], %{private: %{mazurka_resource: resource}}, _, _, _) do
    {:ok, resource}
  end

  @doc false
  def get_elem(resource, index) when is_tuple(resource) do
    if tuple_size(resource) > index + 1 do
      elem(resource, index + 1)
    else
      nil
    end
  end
  def get_elem(resource, -1) do
    resource
  end
  def get_elem(_, _) do
    nil
  end
end

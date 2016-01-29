defmodule Mazurka.Resource.Resource do
  @doc false
  def format({{:., _, [{:__aliases__, _, [:Resource]}, :self]}, _, []}, type) do
    get_resource(type)
  end
  def format({{:., _, [input, :self]}, _, []}, type) when input in [:Resource, Elixir.Resource, __MODULE__] do
    get_resource(type)
  end
  def format({{:., _, [{:__aliases__, _, [:Resource]}, :name]}, _, []}, type) do
    get_n(type)
  end
  def format({{:., _, [input, :name]}, _, []}, type) when input in [:Resource, Elixir.Resource, __MODULE__] do
    get_n(type)
  end
  def format({{:., _, [{:__aliases__, _, [:Resource]}, :params]}, _, []}, type) do
    get_params(type)
  end
  def format({{:., _, [input, :params]}, _, []}, type) when input in [:Resource, Elixir.Resource, __MODULE__] do
    get_params(type)
  end
  def format({{:., _, [{:__aliases__, _, [:Resource]}, :param]}, _, [name]}, type) do
    get_p(type, name)
  end
  def format({{:., _, [input, :param]}, _, [name]}, type) when input in [:Resource, Elixir.Resource, __MODULE__] do
    get_p(type, name)
  end
  def format(other, _) do
    other
  end

  defp get_resource(:prop) do
    {:etude_prop, [], [:resource]}
  end
  defp get_resource(:conn) do
    quote do
      ^^Mazurka.Resource.Resource.self()
    end
  end
  defp get_params(:prop) do
    {:etude_prop, [], [:resource_params]}
  end
  defp get_params(:conn) do
    quote do
      ^^Mazurka.Resource.Resource.resource_params()
    end
  end
  defp get_n(:prop) do
    quote do
      ^Mazurka.Resource.Resource.get_name(unquote(get_resource(:prop)))
    end
  end
  defp get_n(:conn) do
    quote do
      ^Mazurka.Resource.Resource.get_name(unquote(get_resource(:conn)))
    end
  end
  defp get_p(:prop, index) do
    quote do
      ^Mazurka.Resource.Resource.get_param(unquote(get_params(:prop)), unquote(index))
    end
  end
  defp get_p(:conn, index) do
    quote do
      ^Mazurka.Resource.Resource.get_param(unquote(get_params(:conn)), unquote(index))
    end
  end

  @doc false
  def self([], %{private: %{mazurka_resource: resource}}, _, _, _) do
    {:ok, resource}
  end

  @doc false
  def resource_params([], %{private: %{mazurka_resource_params: resource_params}}, _, _, _) do
    {:ok, resource_params}
  end

  @doc false
  def get_name(resource) when is_tuple(resource) do
    resource |> elem(0)
  end
  def get_name(resource) do
    resource
  end

  @doc false
  def get_param(params, name) when is_map(params) do
    Map.get(params, name)
  end
  def get_param(_, _) do
    nil
  end
end

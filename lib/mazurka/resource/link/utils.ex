defmodule Mazurka.Resource.Link.Utils do
  def resource_to_module(module) when is_atom(module) do
    module
  end
  def resource_to_module(resource) when is_tuple(resource) do
    resource |> elem(0)
  end
end

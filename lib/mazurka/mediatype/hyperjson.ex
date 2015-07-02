defmodule Mazurka.Mediatype.Hyperjson do
  use Mazurka.Mediatype

  def content_types do
    [{"application", "hyper+json", %{}},
     {"application", "hyper+msgpack", %{}},
     {"application", "json", %{}}]
  end

  def affordance(affordance, props = %{input: _input}, _) do
    %{
      "method" => affordance.method,
      "action" => to_string(affordance)
    }
    |> Dict.merge(props)
  end
  def affordance(%{method: "GET"} = affordance, props, _) do
    %{
      "href" => to_string(affordance)
    }
    |> Dict.merge(props || %{})
  end
  def affordance(affordance, props, _) do
    %{
      "method" => affordance.method,
      "action" => to_string(affordance)
    }
    |> Dict.merge(props || %{})
  end
end
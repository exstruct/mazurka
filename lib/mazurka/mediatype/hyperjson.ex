defmodule Mazurka.Mediatype.Hyperjson do
  def content_types(_) do
    [{"application", "hyper+json", %{}},
     {"application", "hyper+msgpack", %{}},
     {"application", "json", %{}}]
  end

  def affordance(affordance, props = %{input: _input}) do
    %{
      "method" => affordance.method,
      "action" => to_string(affordance)
    }
    |> Dict.merge(props)
  end
  def affordance(affordance, props) do
    %{
      "href" => to_string(affordance)
    }
    |> Dict.merge(props || %{})
  end
end
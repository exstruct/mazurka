defmodule Mazurka.Mediatype.Hyper do
  use Mazurka.Mediatype
  alias Mazurka.Resource.Utils

  def content_types do
    [{"application", "json", %{}},
     {"application", "hyper+json", %{}},
     {"application", "hyper+x-erlang-binary", %{}},
     {"application", "hyper+msgpack", %{}}]
  end

  defmacro handle_action(block) do
    quote location: :keep do
      case unquote(block) do
        %{__struct__: _} = response ->
          response
        response when is_map(response) and not is_nil(unquote(Utils.router)) ->
          Map.put_new(response, "href", to_string(rel_self()))
        response ->
          response
      end
    end
  end

  defmacro handle_affordance(affordance, props) do
    quote location: :keep do
      affordance = unquote(affordance)
      props = Mazurka.Mediatype.Hyper.__noop__(unquote(props)) || %{}
      case {affordance, props} do
        {%{__struct__: struct} = affordance, _} when struct in [Mazurka.Affordance.Undefined, Mazurka.Affordance.Unacceptable] ->
          affordance
        {%Mazurka.Affordance{} = affordance, %{"input" => _} = props} ->
          %{
            "method" => Map.get(affordance, :method),
            "action" => to_string(affordance)
          } |> Map.merge(props)
        {%Mazurka.Affordance{method: "GET"} = affordance, props} ->
          %{
            "href" => to_string(affordance)
          } |> Map.merge(props)
        {%Mazurka.Affordance{} = affordance, props} ->
          %{
            "method" => Map.get(affordance, :method),
            "action" => to_string(affordance),
            "input" => %{}
          } |> Map.merge(props)
      end
    end
  end

  def __noop__(value) do
    value
  end
end

defmodule Mazurka.Mediatype.Hyper do
  use Mazurka.Mediatype
  use Mazurka.Resource.Utils

  def __content_types__ do
    [{"application", "json", %{}},
     {"application", "hyper+json", %{}},
     {"application", "hyper+x-erlang-binary", %{}},
     {"application", "hyper+msgpack", %{}}]
  end

  defmacro __handle_action__(block) do
    quote location: :keep do
      case unquote(block) do
        %{__struct__: _} = response ->
          response
        response when is_map(response) and not is_nil(unquote(Utils.router)) ->
          Map.put(response, "href", to_string(rel_self()))
        response ->
          response
      end
    end
  end

  defmacro __handle_affordance__(affordance, props) do
    quote location: :keep do
      case {unquote(affordance), unquote(props) || %{}} do
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
end

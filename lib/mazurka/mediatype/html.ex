defmodule Mazurka.Mediatype.HTML do
  use Mazurka.Mediatype

  def __content_types__ do
    [{"text", "html", %{}}]
  end

  defmacro __handle_action__(block) do
    block
  end

  defmacro __handle_affordance__(affordance, props) do
    quote location: :keep do
      affordance = unquote(affordance)
      case {affordance, unquote(props) || to_string(affordance)} do
        {%{__struct__: struct}, _} when struct in [Mazurka.Affordance.Undefined, Mazurka.Affordance.Unacceptable] ->
          nil
        {%Mazurka.Affordance{method: "GET"} = affordance, name} when is_binary(name) ->
          {"a", %{"href" => to_string(affordance)}, name}
        {%Mazurka.Affordance{method: method} = affordance, name} when is_binary(name) ->
          {"form", %{"method" => method, "action" => to_string(affordance)}, [
            {"input", %{"type" => "submit"}, name}
          ]}
        {%Mazurka.Affordance{} = affordance, {"a", props, children}} ->
          {"a", Map.put(props, "href", to_string(affordance)), children}
        {%Mazurka.Affordance{method: method} = affordance, {"form", props, children}} ->
          {"form", Map.merge(%{"method" => method, "action" => to_string(affordance)}, props), children}
        {_, {_, _, _} = element} ->
          element
        {%Mazurka.Affordance{method: method} = affordance, children} when is_list(children) ->
          {"form", %{"method" => method, "action" => to_string(affordance)}, children}
      end
    end
  end
end

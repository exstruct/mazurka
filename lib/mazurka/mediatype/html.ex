defmodule Mazurka.Mediatype.HTML do
  use Mazurka.Mediatype

  def name do
    HTML
  end

  def content_types do
    [{"text", "html", %{}, Mazurka.Format.HTML}]
  end

  def format_affordance(affordance, name) when is_binary(name) do
    format_affordance(affordance, %{"name" => name})
  end
  def format_affordance(affordance, element) when is_tuple(element) do
    props = elem(element, 1) || %{}
    case elem(element, 0) do
      "form" ->
        put_elem(element, 1, Dict.merge(%{"action" => to_string(affordance),
                                          "method" => affordance.method}))
      _ ->
        put_elem(element, 1, Dict.put(props, "href", to_string(affordance)))
    end
  end
  def format_affordance(affordance, %{"input" => input}) do
    {"form", [{"method", affordance.method}, {"action", to_string(affordance)}],
      input
    }
  end
  def format_affordance(%{method: "GET"} = affordance, props) do
    props = props || %{}
    name = Map.get(props, "name", "")

    props = props
    |> Map.put("href", to_string(affordance))
    |> Map.delete("name")

    {"a", props, name}
  end
  def format_affordance(affordance, props) do
    {"form", [{"method", affordance.method}, {"action", to_string(affordance)}],
      Map.get(props, "input")
    }
  end

  defmacro handle_action(block) do
    block
  end

  defmacro handle_affordance(affordance, props) do
    quote do
      affordance = unquote(affordance)
      if affordance do
        ^Mazurka.Mediatype.HTML.format_affordance(affordance, unquote(props))
      else
        affordance
      end
    end
  end

  defmacro handle_error(block) do
    block
  end
end

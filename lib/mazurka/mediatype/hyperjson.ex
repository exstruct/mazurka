defmodule Mazurka.Mediatype.Hyperjson do
  use Mazurka.Mediatype

  def name do
    Hyperjson
  end

  def content_types do
    [{"application", "json", %{}, Mazurka.Format.JSON},
     {"application", "hyper+json", %{}, Mazurka.Format.JSON},
     {"application", "hyper+x-erlang-binary", %{}, Mazurka.Format.ERLANG_TERM},
     {"application", "hyper+msgpack", %{}, Mazurka.Format.MSGPACK}]
  end

  def optional_types do
    [{"application", "json", %{}, Mazurka.Format.JSON},
     {"application", "x-erlang-binary", %{}, Mazurka.Format.ERLANG_TERM},
     {"application", "msgpack", %{}, Mazurka.Format.MSGPACK}]
  end

  def format_affordance(affordance, props = %{"input" => _input}) do
    %{
      "method" => affordance.method,
      "action" => to_string(affordance)
    }
    |> Dict.merge(props)
  end
  def format_affordance(%{method: "GET"} = affordance, props) do
    %{
      "href" => to_string(affordance)
    }
    |> Dict.merge(props || %{})
  end
  def format_affordance(affordance, props) do
    %{
      "method" => affordance.method,
      "action" => to_string(affordance)
    }
    |> Dict.merge(props || %{})
  end

  defmacro handle_action(block) do
    quote do
      response = unquote(block)
      if ^:erlang.is_map(response) do
        ^Dict.put_new(response, "href", Rels.self)
      else
        response
      end
    end
  end

  defmacro handle_affordance(affordance, props) do
    quote do
      affordance = unquote(affordance)
      if affordance do
        ^Mazurka.Mediatype.Hyperjson.format_affordance(affordance, unquote(props))
      else
        affordance
      end
    end
  end

  defmacro handle_error(block) do
    quote do
      response = unquote(block) || %{}

      if ^:erlang.is_map(response) do
        response
        |> ^Dict.put_new("href", Rels.self)
        |> ^Dict.put_new("error", %{
          "message" => "Internal server error"
        })
      else
        response
      end
    end
  end
end

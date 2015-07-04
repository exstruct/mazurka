defmodule Mazurka.Mediatype.Hyperjson do
  use Mazurka.Mediatype

  def name do
    Hyperjson
  end

  def content_types do
    [{"application", "hyper+json", %{}, Mazurka.Format.JSON},
     {"application", "hyper+x-erlang-binary", %{}, Mazurka.Format.ERLANG_TERM},
     {"application", "hyper+msgpack", %{}, Mazurka.Format.MSGPACK},
     {"application", "json", %{}, Mazurka.Format.JSON}]
  end

  def optional_types do
    [{"application", "json", %{}, Mazurka.Format.JSON},
     {"application", "x-erlang-binary", %{}, Mazurka.Format.ERLANG_TERM},
     {"application", "msgpack", %{}, Mazurka.Format.MSGPACK}]
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

  defmacro handle_action(block) do
    quote do
      response = unquote(block)
      if ^:erlang.is_map(response) do
        ^Dict.put(response, "href", Rels.self)
      else
        response
      end
    end
  end

  defmacro handle_affordance(block) do
    quote do
      response = unquote(block)
      if ^:erlang.is_map(response) do
        ^Dict.put(response, "href", Rels.self)
      else
        response
      end
    end
  end

  defmacro handle_error(block) do
    quote do
      response = unquote(block) || %{}

      if ^:erlang.is_map(response) do
        response
        |> ^Dict.put("href", Rels.self)
        |> ^Dict.put_new("error", %{
          "message" => "Internal server error"
        })
      else
        response
      end
    end
  end
end
defmodule MazurkaTest.Resources.Partials do
  use Mazurka.Resource

  param name

  mediatype Hyperjson do
    action do
      %{
        "message" => %MazurkaTest.Partials.Content.message{name: name}
      }
    end
  end

  test "should work" do
    conn = request do
      params %{"name" => "Joe"}
    end

    assert conn.status == 200
    assert String.contains?(conn.resp_body, "Joe")
  end
end

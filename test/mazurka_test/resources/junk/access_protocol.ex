defmodule MazurkaTest.Resources.AccessProtocol do
  use Mazurka.Resource

  param key

  let user = %{"name" => "Joe"}

  mediatype Hyperjson do
    action do
      %{
        "value" => user[key]
      }
    end
  end

  test "should work" do
    request do
      params %{"key" => "name"}
    end
  after conn ->
    conn
    |> assert_status(200)
    |> assert_json(%{"value" => "Joe"})
  end
end

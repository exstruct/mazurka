defmodule MazurkaTest.Resources.Validation do
  use Mazurka.Resource

  param key

  validation key == "hello"

  mediatype Hyperjson do
    action do
      %{
        "key" => key
      }
    end
  end

  test "should validate the input" do
    request do
      params %{"key" => "name"}
    end
  after conn ->
    conn
    |> refute_status(200)
  end

  test "should work" do
    request do
      params %{"key" => "hello"}
    end
  after conn ->
    conn
    |> assert_status(200)
  end
end

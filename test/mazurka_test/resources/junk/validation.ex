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
    conn = request do
      params %{"key" => "name"}
    end

    assert conn.status != 200
  end

  test "should work" do
    conn = request do
      params %{"key" => "hello"}
    end

    assert conn.status == 200
  end
end

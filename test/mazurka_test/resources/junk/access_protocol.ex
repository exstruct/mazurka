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
    conn = request do
      params %{"key" => "name"}
    end

    assert conn.status == 200
    assert String.contains?(conn.resp_body, "Joe")
  end
end

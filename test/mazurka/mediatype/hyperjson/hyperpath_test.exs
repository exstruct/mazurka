defmodule Mazurka.Mediatype.Hyperjson.Hyperpath.Test do
  use ExUnit.Case, async: true
  import MazurkaTest.HTTP.Router

  test "hyperpath works" do
    user = %{"href" => "/users/1"}
    root = hyperpath user.root
    assert root["href"]
  end
end
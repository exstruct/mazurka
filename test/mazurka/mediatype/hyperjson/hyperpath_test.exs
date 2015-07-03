defmodule Mazurka.Mediatype.Hyperjson.Hyperpath.Test do
  use ExUnit.Case, async: true
  import MazurkaTest.HTTP.Router

  test "hyperpath works" do
    # IO.inspect hyperpath _.account.display_name
    user = %{"href" => "/users/1"}
    IO.inspect hyperpath user.root
  end
end
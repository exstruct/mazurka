defmodule MazurkaTest.Resources.PrivateMacro do
  use Mazurka.Resource

  defmacrop create_map(key, value) do
    {:%{}, [], [{key, value}]}
  end

  mediatype Hyperjson do
    action do
      create_map("foo", "bar")
    end
  end

  # test "should work" do
  #   conn = request do
  #     accept "hyper+json"
  #   end

  #   assert conn.status == 200
  # end
end

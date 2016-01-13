defmodule MazurkaTest.Resources.QueryParam do
  use Mazurka.Resource

  mediatype Hyperjson do
    action do
      %{
        "bar" => link_to(MazurkaTest.Resources.QueryParamLink, [], %{"foo" => "bar"}),
        "baz" => link_to(MazurkaTest.Resources.QueryParamLink, [], %{"foo" => "baz"}),
      }
    end
  end

  test "should work" do
    request()
  after conn ->
    conn
    |> assert_status(200)
    |> assert_json(%{"bar" => %{"value" => "bar"},
                     "baz" => %{"value" => "baz"}})
  end
end

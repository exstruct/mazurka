defmodule MazurkaTest.Resources.Parameterized do
  use Mazurka.Resource

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        "name" => Resource.name,
        "param" => Resource.param(0)
      }
    end
  end

  test "should respond with a 200" do
    request()
  after conn ->
    conn
    |> assert_status(200)
    |> assert_json(%{"name" => to_string(Resource.name),
                     "param" => Resource.param(0)})
  end
end

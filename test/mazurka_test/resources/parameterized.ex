defmodule MazurkaTest.Resources.Parameterized do
  use Mazurka.Resource

  let name = Resource.param(:name)

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        "resource" => Resource.name,
        "name" => name
      }
    end

    affordance do
      %{
        "name" => name
      }
    end
  end

  test "should respond with a 200" do
    request()
  after conn ->
    conn
    |> assert_status(200)
    |> assert_json(%{"resource" => to_string(Resource.name),
                     "name" => Resource.param(:name)})
  end
end

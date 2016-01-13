defmodule MazurkaTest.Resources.Case do
  use Mazurka.Resource

  param number

  mediatype Hyperjson do
    action do
      case number do
        "1" -> 1
        "2" -> 4
        "3" -> 9
        "4" -> 16
        "5" -> 25
      end
    end
  end

  test "should work" do
    request do
      params %{"number" => "3"}
    end
  after conn ->
    conn
    |> assert_status(200)
    |> assert_body("9")
  end
end

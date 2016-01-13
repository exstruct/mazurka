defmodule MazurkaTest.Resources.Posts.Read do
  use Mazurka.Resource

  param post do
    Posts.get(value)
  end

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        "title" => post |> load() |> ^Map.get(:title),
        "null_title" => post |> ^Map.get(:title),
        "comments" => for comment <- post.comments do
          %{
            "title" => "comment #{comment}"
          }
        end
      }
    end
  end

  test "should respond to a request" do
    request do
      params %{"post" => "123"}
    end
  after conn ->
    conn
    |> assert_status(200)
    |> assert_json(%{"comments" => [ _ | _],
                     "title" => "Hello!",
                     "null_title" => nil})
  end
end

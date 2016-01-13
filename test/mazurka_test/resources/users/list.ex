defmodule MazurkaTest.Resources.Users.List do
  use Mazurka.Resource
  alias MazurkaTest.Resources

  let users = Users.list()

  mediatype Hyperjson do
    action do
      %{
        "collection" => for user <- users do
          link_to(Resources.Users.Read, user: user)
        end,
      }
    end
  end

  mediatype Text do
    provides "text/css"

    action do
      baz = 123
      """
      .foo {
        bar: #{baz};
      }
      """
    end
  end

  test "should respond with a 200" do
    request()
  after conn ->
    conn
    |> assert_status(200)
    |> assert_json(%{"collection" => [ _ | _ ]})
  end

  test "it should respond with text/css" do
    request do
      accept "text/css"
    end
  after conn ->
    conn
    |> assert_status(200)
    |> assert_body_contains(".foo")
    |> assert_body_contains("123")
  end
end

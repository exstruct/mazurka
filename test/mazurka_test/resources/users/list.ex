defmodule MazurkaTest.Resources.Users.List do
  use Mazurka.Resource
  alias MazurkaTest.Resources

  let users = Users.list()

  mediatype Hyperjson do
    action do
      %{
        "collection" => for user <- users do
          link_to(Resources.Users.Read, user: user)
        end
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

  test "it should response with a 200" do
    conn = request do
      accept "hyper+json"
    end

    assert conn.status == 200
    assert conn.resp_body

    resp_body = Mazurka.Format.JSON.decode(conn.resp_body)
    assert resp_body["collection"]
    assert length(resp_body["collection"]) > 0
  end

  test "it should respond with text/css" do
    conn = request do
      accept "text/css"
    end

    assert conn.status == 200
    assert String.starts_with?(conn.resp_body, ".foo")
    assert String.contains?(conn.resp_body, "123")
  end
end

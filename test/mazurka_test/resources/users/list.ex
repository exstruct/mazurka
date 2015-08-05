defmodule MazurkaTest.Resources.Users.List do
  use Mazurka.Resource
  alias MazurkaTest.Resources

  let users = Users.list()

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        "collection" => for user <- users do
          link_to(Resources.Users.Read, user: user)
        end
      }
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
end

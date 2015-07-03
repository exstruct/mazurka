defmodule Mazurka.Protocol.Http.Request.Test do
  use ExUnit.Case, async: true

  require MazurkaTest.HTTP.Router

  test "it makes a request to the router" do
    conn = MazurkaTest.HTTP.Router.request do
      get "/"
      accept "hyper+json"
    end

    assert conn.status == 200
    assert length(conn.resp_headers) > 1
    assert byte_size(conn.resp_body) > 0
  end
end

defmodule MazurkaTest.Resources.TransitionToBinary do
  use Mazurka.Resource

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      transition_to("/foo")
    end
  end

  test "should redirect to '/foo'" do
    conn = request do
    end

    assert conn.status == 303
    assert :proplists.get_value("location", conn.resp_headers) == "/foo"
  end
end

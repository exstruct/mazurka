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
    conn = request do
    end

    assert conn.status == 200
    body = Poison.decode!(conn.resp_body)
    assert %{"bar" => %{"value" => "bar"}, "baz" => %{"value" => "baz"}} = body
  end
end

defmodule Mazurka.Protocol.HTTP.Graph do
  use Mazurka.Resource

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      ^^Mazurka.Protocol.HTTP.Graph.graph()
    end
  end

  @doc false
  Kernel.def graph(_, conn, _, _, _) do
    {:ok, conn.private.mazurka_router.graph()}
  end

  test "should respond with a graph of the resources" do
    conn = request do
      accept "hyper+json"
    end

    assert conn.status == 200
  end
end
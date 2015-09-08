defmodule MazurkaTest.Resources.Multiple do
  use Mazurka.Resource

  mediatype Hyperjson do
    action do
      %{}
    end
  end

  test "should work" do
    conn = request do
      accept "hyper+json"
    end
    assert conn.status == 200
  end
end

defmodule MazurkaTest.Resources.Modules do
  use Mazurka.Resource

  mediatype Hyperjson do
    action do
      %{}
    end
  end

  test "should work" do
    conn = request do
      accept "hyper+json"
    end
    assert conn.status == 200
  end
end

defmodule MazurkaTest.Resources.Case do
  use Mazurka.Resource

  mediatype Hyperjson do
    action do
      case ^:random.uniform(5) do
        1 -> 1
        2 -> 4
        3 -> 9
        4 -> 16
        5 -> 25
      end
    end
  end

  test "should work" do
    conn = request do

    end

    IO.inspect conn
  end
end

defmodule MazurkaTest do
  use ExUnit.Case

  require MazurkaTest.Router

  test "the truth" do
    conn = MazurkaTest.Router.request do
      get "/"
      accept "hyper+x-erlang-binary"
    end

    IO.inspect conn.resp_body |> Mazurka.Format.ERLANG_TERM.decode
  end
end

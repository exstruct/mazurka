defmodule Mazurka.Test do
  use ExUnit.Case

  require MazurkaTest.HTTP.Router

  test "the truth" do
    conn = MazurkaTest.HTTP.Router.request do
      get "/"
      accept "hyper+x-erlang-binary"
    end

    IO.inspect conn.resp_body |> Mazurka.Format.ERLANG_TERM.decode
  end
end

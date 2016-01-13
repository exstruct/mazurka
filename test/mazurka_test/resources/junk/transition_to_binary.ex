defmodule MazurkaTest.Resources.TransitionToBinary do
  use Mazurka.Resource

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      transition_to("/foo")
    end
  end

  test "should redirect to '/foo'" do
    request()
  after conn ->
    conn
    |> assert_status(303)
    |> assert_transition("/foo")
  end
end

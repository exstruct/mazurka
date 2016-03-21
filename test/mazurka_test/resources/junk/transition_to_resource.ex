defmodule MazurkaTest.Resources.TransitionToResource do
  use Mazurka.Resource

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      transition_to(MazurkaTest.Resources.Users.List)
    end
  end

  test "should redirect to a Resource" do
    request()
  after conn ->
    conn
    |> assert_status(303)
    |> assert_transition(MazurkaTest.Resources.Users.List)
  end

  test "should redirect to a url binary" do
    request()
  after conn ->
    conn
    |> assert_status(303)
    |> assert_transition("http://www.example.com/users")
  end

  test "should redirect to a path binary" do
    request()
  after conn ->
    conn
    |> assert_status(303)
    |> assert_transition("/users")
  end

end

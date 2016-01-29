defmodule MazurkaTest.Resources.Root do
  @moduledoc """
  Root resource, here.
  """

  use Mazurka.Resource
  alias MazurkaTest.Resources

  let user_id = Auth.user_id

  @doc """
  This is a foo
  """
  let foo = 123

  @doc """
  This is a mediatype
  """
  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        "account" => link_to(Resources.Users.Read, user: user_id),
        "one" => link_to({Resources.Parameterized, One}),
        "two" => link_to({Resources.Parameterized, Two}),
        "foo" => foo
      }
    end
  end

  event do
    :ok
  end

  event do
    :ok
  end

  test "should respond with a 200" do
    request()
  after conn ->
    conn
    |> assert_status(200)
  end

  @tag :test_tag_disabled
  test "should not run" do
    request()
  after _conn ->
    refute true
  end
end

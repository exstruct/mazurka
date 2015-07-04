defmodule MazurkaTest.Resources.Root do
  use Mazurka.Resource
  alias MazurkaTest.Resources
  alias Resources.Users
  # alias Resources.Oauth
  # alias Resources.Search
  # alias Resources.Translations

  let user_id do
    Auth.user_id
  end

  let foo = 123

  event do
    :ok
  end

  event do
    :ok
  end

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      user = %Users{user: user_id}
      %{
        "account" => user,
        "foo" => foo
        # oauth: %Oauth{},
        # search: %Search{} |> pointer :search,
        # translations: %Translations{}
      }
    end

    affordance do
      %{
        "input": %{}
      }
    end
  end

  test "should response with a 200" do
    conn = request do
      accept "hyper+json"
    end

    assert conn.status == 200
  end
end
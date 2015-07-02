defmodule MazurkaTest.Resources.Root do
  use Mazurka.Resource
  alias MazurkaTest.Resources
  alias Resources.Users
  alias Resources.Oauth
  alias Resources.Search
  alias Resources.Translations

  let user_id do
    Auth.user_id
  end

  let foo = 123

  event do
    213
  end

  condition foo == 45, foo

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      user = %Users{user: user_id}
      %{
        account: user,
        foo: foo
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

    error foo(err) do
      %{}
    end
  end
end
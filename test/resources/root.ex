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

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        account: user_id &&& %Users{user: user_id},
        oauth: %Oauth{},
        search: %Search{} |> pointer :search,
        translations: %Translations{}
      }
    end
  end
end
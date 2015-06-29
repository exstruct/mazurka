defmodule MazurkaTest.Resources.Users do
  use Mazurka.Resource
  alias MazurkaTest.Resources
  alias Resources.Users.Update
  alias Resources.Users.UpdateImage

  param user

  let user do
    Users.get(Params.user)
  end

  let is_owner do
    Params.user == Auth.user_id
  end

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        id: Params.user,
        is_user: true,
        created_at: user.created_at,
        display_name: user.display_name,
        email: is_owner &&& user.email,
        nickname: user.nickname,
        image: image(),
        update: %Update{user: Params.user}
      }
    end

    defp image() do
      ^IO.inspect :foo
      Hyper.image_form(%{
        affordance: %UpdateImage{user: Params.user},
        value: user.image_url
      })
    end
  end

  mediatype Mazurka.Mediatype.Html do
    action do
      html do
        body do
          div [class: "user"] do
            span [class: "display_name"], user.created_at
          end
        end
      end
    end
  end
end
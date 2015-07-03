defmodule MazurkaTest.Resources.Users.UpdateImage do
  use Mazurka.Resource
  alias MazurkaTest.Resources
  alias MazurkaTest.Resources.Users

  # param user

  # condition Params.user == Auth.user_id

  # let user do
  #   Users.get(Params.user)
  # end

  # mediatype Mazurka.Mediatype.Hyperjson do
  #   action do
  #     Users.update(Params.user, %{
  #       image_url: Input.value
  #     })
  #     Res.redirect(%Users{user: Params.user})
  #   end

  #   affordance do
  #     %Hyper.Image{
  #       value: user.image_url
  #     }
  #   end
  # end
end
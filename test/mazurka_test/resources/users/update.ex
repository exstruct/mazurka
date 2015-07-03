defmodule MazurkaTest.Resources.Users.Update do
  use Mazurka.Resource
  alias MazurkaTest.Resources
  alias MazurkaTest.Resources.Users

  # param user

  # condition Params.user == Auth.user_id, permission_error

  # let user do
  #   Users.get(Params.user)
  # end

  # mediatype Mazurka.Mediatype.Hyperjson do
  #   action do
  #     Users.update(Params.user, %{
  #       email: Input.email,
  #       full_name: Input.full_name,
  #       nickname: Input.nickname,
  #       password: Input.password,
  #       password_confirm: Input.password_confirm
  #     })
  #     Res.redirect(%Users{user: Params.user})
  #   end

  #   affordance do
  #     %{
  #       full_name: %{
  #         type: "text",
  #         value: user.full_name
  #       },
  #       email: %{
  #         type: "email",
  #         value: user.email
  #       },
  #       password: %{
  #         type: "password"
  #       },
  #       password_confirm: %{
  #         type: "password"
  #       }
  #     }
  #   end

  #   event do

  #   end

  #   error permission_error(_err) do
  #     %{
  #       error: %{
  #         message: "You don't have permission to update this user"
  #       }
  #     }
  #   end
  # end
end
defmodule MazurkaTest.Resources.Users.Update do
  use Mazurka.Resource
  alias MazurkaTest.Resources

  param user do
    Users.get(value)
  end

  condition user.id == Auth.user_id, permission_error

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      ## TODO use Etude.Dict.put
      # user
      # |> Dict.put("email", Input.get("email"))
      # |> Dict.put("full_name", Input.get("full_name"))
      # |> Dict.put("nickname", Input.get("nickname"))
      # |> Dict.put("password", Input.get("password"))
      # |> Dict.put("password_confirm", Input.get("password_confirm"))
      # |> Users.update()
      Users.update(user.id, %{
        "email" => Input.get("email"),
        "full_name" => Input.get("full_name"),
        "nickname" => Input.get("nickname"),
        "password" => Input.get("password"),
        "password_confirm" => Input.get("password_confirm")
      })

      invalidates(Resources.Users.Read, user: user)

      transition_to(Resources.Users.Read, user: user)
    end

    affordance do
      %{
        "input" => %{
          "full_name" => %{
            "type" => "text",
            "value" => user.full_name
          },
          "email" => %{
            "type" => "email",
            "value" => user.email
          },
          "password" => %{
            "type" => "password"
          },
          "password_confirm" => %{
            "type" => "password"
          }
        }
      }
    end

    error permission_error(_err) do
      %{
        "error" => %{
          "message" => "You don't have permission to update this user"
        }
      }
    end
  end

  test "should fail if the user is not authenticated" do
    request do
      params %{"user" => "6"}
      accept "hyper+json"
    end
  after conn ->
    conn
    |> assert_error_status()
  end
end

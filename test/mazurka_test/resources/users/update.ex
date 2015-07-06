defmodule MazurkaTest.Resources.Users.Update do
  use Mazurka.Resource
  alias MazurkaTest.Resources

  param user

  condition Params.get("user") == Auth.user_id, permission_error

  let user = Users.get(Params.get("user"))

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      Users.update(Params.get("user"), %{
        "email" => Input.get("email"),
        "full_name" => Input.full_name,
        "nickname" => Input.nickname,
        "password" => Input.password,
        "password_confirm" => Input.password_confirm
      })

      transition_to Resources.Users, %{user: Params.get("user")}
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
    conn = request do
      params %{"user" => "6"}
      accept "hyper+json"
    end

    assert conn.status != 200
  end
end

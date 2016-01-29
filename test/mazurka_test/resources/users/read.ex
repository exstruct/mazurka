defmodule MazurkaTest.Resources.Users.Read do
  use Mazurka.Resource
  alias MazurkaTest.Resources

  param user do
    try(Users.get(value), not_found: not_found_error)
  end

  let is_owner = user.id == Auth.user_id

  let is_admin = case user.id do
    "1" ->
      true
    "3" ->
      true
    _ ->
      false
  end

  let can_edit = is_owner && is_admin

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        "id" => user.id,
        "root" => link_to(Resources.Root),
        "is_user" => true,
        "created_at" => user.created_at,
        "display_name" => user.display_name,
        "email" => is_owner &&& user.email,
        "nickname" => user.nickname,
        "is_admin" => is_admin,
        "can_edit" => can_edit,
      #   image: image(),
        "update" => link_to(Resources.Users.Update, user: user),
        "interests" => for {id, value} <- [thing: 1, other_thing: 2] do
          %{
            "id" => id,
            "value" => value
          }
        end
      }
    end

    affordance do
      %{
        "name" => user.display_name
      }
    end

    partial image(var) do
      ^IO.inspect {:var, var}
      Hyper.image_form(%{
        affordance: %UpdateImage{user: user.id},
        value: user.image_url
      })
    end

    error not_found_error(err) do
      status(:not_found)

      %{
        "error" => %{
          "message" => "This isn't the user you're looking for"
        }
      }
    end
  end

  # mediatype Mazurka.Mediatype.Html do
  #   action do
  #     html do
  #       body do
  #         div [class: "user"] do
  #           span [class: "display_name"], user.created_at
  #         end
  #       end
  #     end
  #   end
  # end

  test "it should respond with a 200" do
    user = seed(Users)

    request do
      params %{user: user}
      accept "hyper+json"
    end
  after conn ->
    conn
    |> assert_status(200)
    |> assert_json(%{"id" => user.id})
    |> refute_json(%{"update" => _})
  end

  test "it should respond with a 404 when not found" do
    request do
      params %{user: "7"}
      accept "hyper+json"
    end
  after conn ->
    conn
    |> assert_status(404)
  end
end

defmodule MazurkaTest.Resources.Users.Read do
  use Mazurka.Resource
  alias MazurkaTest.Resources

  param user do
    Users.get(value)
  end

  let is_owner = Params.get("user") == Auth.user_id
  # let is_owner = user.id == Auth.user_id

  let is_admin = case Params.get("user") do
    "1" ->
      true
    "3" ->
      true
    _ ->
      false
  end

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        "id" => Params.get("user"),
        "root" => link_to(Resources.Root),
        "is_user" => true,
        "created_at" => user.created_at,
        "display_name" => user.display_name,
        "email" => is_owner &&& user.email,
        "nickname" => user.nickname,
        "is_admin" => is_admin,
      #   image: image(),
        "update" => link_to(Resources.Users.Update, %{user: Params.get("user")})
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

  test "it should response with a 200" do
    conn = request do
      params %{"user" => "6"}
      accept "hyper+json"
    end

    assert conn.status == 200
    assert conn.resp_body

    resp_body = Mazurka.Format.JSON.decode(conn.resp_body)

    assert resp_body["id"]
    assert !resp_body["update"]
  end
end

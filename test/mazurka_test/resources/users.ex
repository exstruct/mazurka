defmodule MazurkaTest.Resources.Users do
  use Mazurka.Resource
  alias MazurkaTest.Resources

  param user

  let user = Users.get(Params.user)
  let is_owner = Params.user == Auth.user_id

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        "id" => Params.user,
        "root" => link_to(Resources.Root),
        "is_user" => true,
        "created_at" => user.created_at,
        "display_name" => user.display_name,
        "email" => is_owner &&& ^Dict.get(user, "email"),
        "nickname" => user.nickname,
      #   image: image(),
        "update" => link_to(Resources.Users.Update, %{user: Params.user})
      }
    end

    affordance do
      %{
        # "name" => user.display_name
      }
    end

    # partial image() do
    #   ^IO.inspect :foo
    #   Hyper.image_form(%{
    #     affordance: %UpdateImage{user: Params.user},
    #     value: user.image_url
    #   })
    # end
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

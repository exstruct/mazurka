defmodule MazurkaTest.Resources.Users do
  use Mazurka.Resource
  # alias MazurkaTest.Resources
  # alias Resources.Users.Update
  # alias Resources.Users.UpdateImage

  # test = "this is a test"

  param user

  # let user = Users.get(Params.user)
  # let is_owner = Params.user == Auth.user_id

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      123
      %{
        "root" => %{"href" => "/"}
      }
      # unquote(test)
      # %{
      #   id: Params.user,
      #   is_user: true,
      #   created_at: user.created_at,
      #   display_name: user.display_name,
      #   email: is_owner &&& user.email,
      #   nickname: user.nickname,
      #   image: image(),
      #   update: %Update{user: Params.user}
      # }
    end

    affordance do
      %{
        "foo" => 456
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
  end
end

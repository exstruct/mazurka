defmodule MazurkaTest.Resources.HelperMacro.Helper do
  defmacro edit_form(value) do
    quote do
      link = link_to(MazurkaTest.Resources.HelperMacro)
      if link && unquote(value) do
        %{
          "data" => unquote(value),
          "edit" => link
        }
      else
        unquote(value)
      end
    end
  end
end

defmodule MazurkaTest.Resources.HelperMacro do
  use Mazurka.Resource
  require MazurkaTest.Resources.HelperMacro.Helper

  let value = Input.get("value")

  mediatype Hyperjson do
    action do
      %{
        "link" => MazurkaTest.Resources.HelperMacro.Helper.edit_form(value)
      }
    end
  end

  test "should not return a link" do
    request do
      accept "hyper+json"
    end
  after conn ->
    conn
    |> assert_status(200)
    |> refute_json(%{"link" => %{"edit" => _}})
  end

  test "should return a link" do
    request do
      accept "hyper+json"
      query "value", "foo"
    end
  after conn ->
    conn
    |> assert_status(200)
    |> assert_json(%{"link" => %{"edit" => _}})
  end
end

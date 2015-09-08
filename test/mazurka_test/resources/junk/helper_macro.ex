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
    conn = request do
      accept "hyper+json"
    end

    assert conn.status == 200
    refute conn.resp_body |> String.contains?("edit")
  end

  test "should return a link" do
    conn = request do
      accept "hyper+json"
      query "value", "foo"
    end

    assert conn.status == 200
    assert conn.resp_body |> String.contains?("edit")
  end
end

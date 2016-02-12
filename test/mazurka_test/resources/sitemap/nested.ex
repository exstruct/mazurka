defmodule MazurkaTest.Resources.Sitemap.Nested do
  use Mazurka.Resource

  mediatype Mazurka.Mediatype.XML do
    action do
      {"urlset", %{"xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9"}, [
        {"url", nil, [
          {"loc", nil, "http://www.mazurka.io"}
        ]}
      ]}
    end
  end

  test "should respond with a 200" do
    request()
  after conn ->
    conn
    |> assert_status(200)
  end
end

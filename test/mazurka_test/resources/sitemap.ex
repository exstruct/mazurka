defmodule MazurkaTest.Resources.Sitemap do
  use Mazurka.Resource

  mediatype Mazurka.Mediatype.XML do
    action do
      {"sitemapindex", %{"xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9"}, [
        {"sitemap", nil, [
          {"loc", nil, link_to(MazurkaTest.Resources.Sitemap.Nested)}
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

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

  mediatype Mazurka.Mediatype.HTML do
    action do
      {"html", [
        {"head", nil, [
          {"title", nil, "Sitemap"}
        ]},
        {"body", nil, [
          link_to(MazurkaTest.Resources.Sitemap.Nested)
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

  test "should respond with html" do
    request do
      accept "html"
    end
  after conn ->
    conn
    |> assert_status(200)
  end
end

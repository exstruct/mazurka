defmodule MazurkaTest.Resources.Xml do
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

  test "should generate xml" do
    request()
  after conn ->
    conn
    |> assert_status(200)
    |> assert_body("""
      <?xml version=\"1.0\" encoding=\"UTF-8\" ?>
      <sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">
      \t<sitemap>
      \t\t<loc>http://www.example.com/sitemap/nested</loc>
      \t</sitemap>
      </sitemapindex>
      """ |> String.rstrip())
  end

  test "should respond with xml" do
    request do
      accept "xml"
    end
  after conn ->
    conn
    |> assert_status(200)
  end
end

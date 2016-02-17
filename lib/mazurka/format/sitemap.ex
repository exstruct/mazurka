defmodule Mazurka.Format.Sitemap do
  def encode(content, opts \\ [])
  def encode(%{index: index}, _opts) do
    links = [index] |> List.flatten |> Enum.uniq |> Enum.map(&transform_link/1)
    {"sitemapindex", %{"xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9"}, links}
    |> XmlBuilder.doc()
  end
  def encode(content, opts) when is_binary(content) do
    encode([content], opts)
  end
  def encode(content, _opts) when is_list(content) do
    urls = content |> Enum.map(&transform_url/1)
    {"urlset", %{"xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9"}, urls}
    |> XmlBuilder.doc()
  end
  def encode(content, _opts) do
    content
    |> XmlBuilder.doc()
  end

  defp transform_link(link) do
    {"sitemap", nil, [
      {"loc", nil, link}
    ]}
  end

  defp transform_url(map = %{}) do
    {"url", nil, Enum.map(map, fn {k, v} -> {k, nil, v} end)}
  end
  defp transform_url(url) do
    {"url", nil, [
      {"loc", nil, url}
    ]}
  end

  def decode(_content, _opts \\ []) do
    throw :Sitemap_decode_not_supported
  end
end

defmodule Mazurka.Mediatype.Sitemap do
  use Mazurka.Mediatype

  def name do
    Sitemap
  end

  def content_types do
    [{"application", "xml", %{}, Mazurka.Format.Sitemap}]
  end

  def format_affordance(affordance, _props = nil) do
    to_string(affordance)
  end
  def format_affordance(_affordance, props) do
    props
  end

  defmacro handle_action(block) do
    block
  end

  defmacro handle_affordance(affordance, props) do
    quote do
      affordance = unquote(affordance)
      if affordance do
        ^Mazurka.Mediatype.Sitemap.format_affordance(affordance, unquote(props))
      else
        affordance
      end
    end
  end

  defmacro handle_error(block) do
    block
  end
end

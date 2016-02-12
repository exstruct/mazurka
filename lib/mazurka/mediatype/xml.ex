defmodule Mazurka.Mediatype.XML do
  use Mazurka.Mediatype

  def name do
    XML
  end

  def content_types do
    [{"application", "xml", %{}, Mazurka.Format.XML}]
  end

  def format_affordance(affordance, _props) do
    to_string(affordance)
  end

  defmacro handle_action(block) do
    block
  end

  defmacro handle_affordance(affordance, props) do
    quote do
      affordance = unquote(affordance)
      if affordance do
        ^Mazurka.Mediatype.XML.format_affordance(affordance, unquote(props))
      else
        affordance
      end
    end
  end

  defmacro handle_error(block) do
    block
  end
end

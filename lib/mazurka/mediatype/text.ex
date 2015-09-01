defmodule Mazurka.Mediatype.Text do
  use Mazurka.Mediatype

  def name do
    Text
  end

  def content_types do
    [{"text", "plain", %{}, Mazurka.Format.TEXT}]
  end

  def format_affordance(%{method: method} = affordance, _props) do
    "#{method} #{affordance}"
  end

  defmacro handle_action(block) do
    block
  end

  defmacro handle_affordance(affordance, props) do
    quote do
      affordance = unquote(affordance)
      if affordance do
        ^Mazurka.Mediatype.Text.format_affordance(affordance, unquote(props))
      else
        affordance
      end
    end
  end

  defmacro handle_error(block) do
    block
  end
end

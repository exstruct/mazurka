defmodule Mazurka.Mediatype.Text do
  use Mazurka.Mediatype

  def content_types do
    [{"text", "plain", %{}}]
  end

  defmacro handle_action(block) do
    block
  end

  defmacro handle_affordance(affordance, props) do
    quote location: :keep do
      to_string(unquote(props) || unquote(affordance))
    end
  end
end

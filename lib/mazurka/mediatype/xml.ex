defmodule Mazurka.Mediatype.XML do
  use Mazurka.Mediatype

  def content_types do
    [{"application", "xml", %{}}]
  end

  defmacro handle_action(block) do
    block
  end

  defmacro handle_affordance(affordance, _props) do
    quote location: :keep do
      to_string(unquote(affordance))
    end
  end
end

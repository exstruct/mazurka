defmodule Mazurka.Mediatype.XML do
  use Mazurka.Mediatype

  def __content_types__ do
    [{"application", "xml", %{}}]
  end

  defmacro __handle_action__(block) do
    block
  end

  defmacro __handle_affordance__(affordance, _props) do
    quote location: :keep do
      to_string(unquote(affordance))
    end
  end
end

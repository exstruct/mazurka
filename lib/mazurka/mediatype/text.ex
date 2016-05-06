defmodule Mazurka.Mediatype.Text do
  use Mazurka.Mediatype

  def __content_types__ do
    [{"text", "plain", %{}}]
  end

  defmacro __handle_action__(block) do
    block
  end

  defmacro __handle_affordance__(affordance, props) do
    quote location: :keep do
      to_string(unquote(props) || unquote(affordance))
    end
  end
end

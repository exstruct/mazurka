defmodule MazurkaTest.Partials.Content do
  use Mazurka.Partial

  defpartial message do
    "Hello, #{prop(name)}"
  end
end

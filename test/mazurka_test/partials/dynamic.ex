defmodule MazurkaTest.Partials.Dynamic do
  use Mazurka.Partial
  
  for name <- [:first, :second] do

    defpartial unquote(name) do
      "#{unquote(name)} called with arg=#{prop(arg)}"
    end

    defpartial unquote(name |> Kernel.to_string |> Kernel.<>("_with_append") |> String.to_atom) do
      "#{unquote(name)}_with_append called with arg=#{prop(arg)}"
    end
  end

  outside = "needs_unquoting"
  defpartial direct do
    "direct called with arg=#{prop(arg)}, outside=#{unquote(outside)}"
  end

  defpartial can_do_it? do
    prop(name) == "Joe"
  end
end
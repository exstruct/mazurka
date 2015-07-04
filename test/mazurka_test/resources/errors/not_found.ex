defmodule MazurkaTest.Resources.Errors.NotFound do
  use Mazurka.Resource

  mediatype Mazurka.Mediatype.Hyperjson do
    action do
      %{
        "error" => %{
          "message" => "Not found"
        }
      }
    end

    affordance do
      %{
        "input": %{}
      }
    end

    error foo(err) do
      %{}
    end
  end
end
defmodule MazurkaTest.Resources.QueryParamLink do
  use Mazurka.Resource

  let foo = Input.get("foo")

  mediatype Hyperjson do
    action do
      foo
    end

    affordance do
      %{
        "value" => foo
      }
    end
  end
end

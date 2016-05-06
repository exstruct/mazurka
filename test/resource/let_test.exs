defmodule Test.Mazurka.Resource.Let do
  use Test.Mazurka.Case

  context Basic do
    resource Foo do
      let foo = 1

      let bar do
        a = 1
        foo + a
      end

      mediatype Hyper do
        action do
          %{"foo" => bar}
        end
      end
    end
  after
    "Foo.action" ->
      {body, _, _} = Foo.action([], %{}, %{}, %{})
      assert %{"foo" => 2} == body
  end
end

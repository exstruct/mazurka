defmodule Test.Mazurka.Resource.Conn do
  use Test.Mazurka.Case

  context ConnAccess do
    resource Foo do
      mediatype Hyper do
        action do
          %{"port" => conn.port}
        end

        affordance do
          %{"port" => conn.port}
        end
      end
    end

    router Router do
      route "GET", [], Foo
    end
  after
    "action" ->
      assert {_, _, _} = Foo.action([], %{"foo" => "foo"}, %{}, %{port: 123})

    "affordance" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "foo"}, %{}, %{port: 123}, Router)
  end
end

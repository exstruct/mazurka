defmodule Test.Mazurka.Resource.Conn do
  use Test.Mazurka.Case

  context "Conn Access" do
    defmodule Foo do
      use Mazurka.Resource

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

  context "Conn Access in let" do
    defmodule Foo do
      use Mazurka.Resource

      let bar = conn.port

      mediatype Hyper do
        action do
          bar
        end
      end
    end
  after
    "action" ->
      assert {_, _, _} = Foo.action([], %{}, %{}, %{port: 123})
  end
end

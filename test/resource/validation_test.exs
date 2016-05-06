defmodule Test.Mazurka.Resource.Validation do
  use Test.Mazurka.Case

  context Single do
    resource Foo do
      param foo

      validation foo != "bar"

      mediatype Hyper do
        action do
          %{"foo" => foo}
        end
      end
    end

    router Router do
      route "GET", ["foo", :foo], Foo
    end
  after
    "action" ->
      assert {_, _, _} = Foo.action([], %{"foo" => "foo"}, %{}, %{})

    "action validation failure" ->
      assert_raise Mazurka.ValidationException, fn ->
        Foo.action([], %{"foo" => "bar"}, %{}, %{})
      end

    "affordance" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "foo"}, %{}, %{}, Router)

    "affordance validation success" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "bar"}, %{}, %{}, Router)
  end

  context Several do
    resource Foo do
      param foo

      validation foo != "bar"
      validation foo != "baz"

      mediatype Hyper do
        action do
          %{"foo" => foo}
        end
      end
    end

    router Router do
      route "GET", ["foo", :foo], Foo
    end
  after
    "action" ->
      assert {_, _, _} = Foo.action([], %{"foo" => "foo"}, %{}, %{})

    "action first condition failure" ->
      assert_raise Mazurka.ValidationException, fn ->
        Foo.action([], %{"foo" => "bar"}, %{}, %{})
      end

    "action second condition failure" ->
      assert_raise Mazurka.ValidationException, fn ->
        Foo.action([], %{"foo" => "baz"}, %{}, %{})
      end

    "affordance" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "foo"}, %{}, %{}, Router)

    "affordance first validation success" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "bar"}, %{}, %{}, Router)

    "affordance second validation success" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "baz"}, %{}, %{}, Router)
  end

  context Ordering do
    resource Foo do
      param foo

      validation foo != "bar"
      validation foo != "baz"
      validation throw(:foo)

      mediatype Hyper do
        action do
          %{"foo" => foo}
        end
      end
    end

    router Router do
      route "GET", ["foo", :foo], Foo
    end
  after
    "action" ->
      catch_throw(Foo.action([], %{"foo" => "foo"}, %{}, %{}))

    "action first condition failure" ->
      assert_raise Mazurka.ValidationException, fn ->
        Foo.action([], %{"foo" => "bar"}, %{}, %{})
      end

    "action second condition failure" ->
      assert_raise Mazurka.ValidationException, fn ->
        Foo.action([], %{"foo" => "baz"}, %{}, %{})
      end

    "affordance" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "foo"}, %{}, %{}, Router)

    "affordance first validation success" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "bar"}, %{}, %{}, Router)

    "affordance second validation sucess" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "baz"}, %{}, %{}, Router)
  end

  context CustomMessage do
    resource Foo do
      param foo

      validation foo != "bar", "Uh oh..."

      mediatype Hyper do
        action do
          %{"foo" => foo}
        end
      end
    end
  after
    "action" ->
      try do
        Foo.action([], %{"foo" => "bar"}, %{}, %{})
      rescue
        e in [Mazurka.ValidationException] ->
          assert e.message == "Uh oh..."
      end
  end
end

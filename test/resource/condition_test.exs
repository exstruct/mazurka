defmodule Test.Mazurka.Resource.Condition do
  use Test.Mazurka.Case

  context Single do
    resource Foo do
      param foo

      condition foo != "bar"

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

    "action conditions failure" ->
      assert_raise Mazurka.ConditionException, fn ->
        Foo.action([], %{"foo" => "bar"}, %{}, %{})
      end

    "affordance" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "foo"}, %{}, %{}, Router)

    "affordance conditions failure" ->
      assert {%Mazurka.Affordance.Undefined{}, _} = Foo.affordance([], %{"foo" => "bar"}, %{}, %{}, Router)
  end

  context Several do
    resource Foo do
      param foo

      condition foo != "bar"
      condition foo != "baz"

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
      assert_raise Mazurka.ConditionException, fn ->
        Foo.action([], %{"foo" => "bar"}, %{}, %{})
      end

    "action second condition failure" ->
      assert_raise Mazurka.ConditionException, fn ->
        Foo.action([], %{"foo" => "baz"}, %{}, %{})
      end

    "affordance" ->
      assert {_, _} = Foo.affordance([], %{"foo" => "foo"}, %{}, %{}, Router)

    "affordance first condition failure" ->
      assert {%Mazurka.Affordance.Undefined{}, _} = Foo.affordance([], %{"foo" => "bar"}, %{}, %{}, Router)

    "affordance second condition failure" ->
      assert {%Mazurka.Affordance.Undefined{}, _} = Foo.affordance([], %{"foo" => "baz"}, %{}, %{}, Router)
  end

  context Ordering do
    resource Foo do
      param foo

      condition foo != "bar"
      condition foo != "baz"
      condition throw(:foo)

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
      assert_raise Mazurka.ConditionException, fn ->
        Foo.action([], %{"foo" => "bar"}, %{}, %{})
      end

    "action second condition failure" ->
      assert_raise Mazurka.ConditionException, fn ->
        Foo.action([], %{"foo" => "baz"}, %{}, %{})
      end

    "affordance" ->
       catch_throw(Foo.affordance([], %{"foo" => "foo"}, %{}, %{}))

    "affordance first condition failure" ->
      assert {%Mazurka.Affordance.Undefined{}, _} = Foo.affordance([], %{"foo" => "bar"}, %{}, %{}, Router)

    "affordance second condition failure" ->
      assert {%Mazurka.Affordance.Undefined{}, _} = Foo.affordance([], %{"foo" => "baz"}, %{}, %{}, Router)
  end

  context CustomMessage do
    resource Foo do
      param foo

      condition foo != "bar", "Uh oh..."

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
        e in [Mazurka.ConditionException] ->
          assert e.message == "Uh oh..."
      end
  end
end

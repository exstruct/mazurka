defmodule Test.Mazurka.Resource.Condition do
  use Test.Mazurka.Case

  context "Simple" do
    @contextdoc """
    In this example, we're going to add a condition that asserts the `foo` param does not equal `"bar"`.
    """

    comment """
    We start by creating a resource and adding the `condition/1` call
    """

    defmodule Foo do
      use Mazurka.Resource

      param foo

      condition foo != "bar"

      mediatype Hyper do
        action do
          %{"foo" => foo}
        end
      end
    end

    comment """
    We'll also set up a router so we can observe how affordances work with failed conditions.
    """

    defmodule Router do
      def resolve(%{resource: Foo, params: %{"foo" => foo}} = affordance, _source, _conn) do
        %{affordance | method: "GET", path: "/foo/#{foo}"}
      end
    end
  after
    """
    Action success

    Here we pass the value of `"baz"` for the `"foo"` param.

    This call should return successfully.
    """ ->
      accepts = [{"application", "hyper+json", %{}}]
      params = %{"foo" => "baz"}
      input = %{}
      conn = %{}
      {response, content_type, _conn} = Foo.action(accepts, params, input, conn, Router)
      assert %{"foo" => "baz"} = response
      assert {"application", "hyper+json", _} = content_type

    """
    Action failure

    In this case we'll pass `"bar"` as the `"foo"` param and we should get
    a `Mazurka.ConditionException`.
    """ ->
      assert_raise Mazurka.ConditionException, fn ->
        accepts = []
        params = %{"foo" => "bar"}
        input = %{}
        conn = %{}
        Foo.action(accepts, params, input, conn)
      end

    """
    Affordance success

    When we call the `Foo.affordance/5` function with valid params we get a valid affordance.
    """ ->
      accepts = [{"application", "hyper+json", %{}}]
      params = %{"foo" => "baz"}
      input = %{}
      conn = %{}
      {affordance, content_type} = Foo.affordance(accepts, params, input, conn, Router)
      assert %{"href" => "/foo/baz"} = affordance
      assert {"application", "hyper+json", _} = content_type

    """
    Affordance failure

    When calling an affordance with invalid data we'll get a `Mazurka.Affordance.Undefined` struct informing us that the affordance was unable to render.
    """ ->
      accepts = [{"application", "hyper+json", %{}}]
      params = %{"foo" => "bar"}
      input = %{}
      conn = %{}
      {affordance, _} = Foo.affordance(accepts, params, input, conn, Router)
      assert %Mazurka.Affordance.Undefined{} = affordance
  end

  context "Several" do
    defmodule Foo do
      use Mazurka.Resource

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

  context "Ordering" do
    defmodule Foo do
      use Mazurka.Resource

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

  context "Custom Message" do
    defmodule Foo do
      use Mazurka.Resource

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

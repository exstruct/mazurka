defmodule Test.Mazurka.Resource.Link do
  use Test.Mazurka.Case

  context Dual do
    resource Foo do
      param foo

      mediatype Hyper do
        action do
          %{"foo" => foo}
        end
      end
    end

    resource Bar do
      param bar

      mediatype Hyper do
        action do
          %{
            "bar" => bar,
            "foo" => link_to(Foo, %{"foo" => bar <> bar})
          }
        end
      end
    end

    router Router do
      route "GET", ["foo", :foo], Foo
      route "POST", ["bar", :bar], Bar
    end
  after
    "Foo.action" ->
      {body, content_type, _} = Foo.action([], %{"foo" => "123"}, %{}, %{}, Router)
      assert %{"foo" => "123", "href" => "/foo/123"} == body
      assert {"application", "json", %{}} = content_type

    "Foo.affordance" ->
      {body, content_type} = Foo.affordance([], %{"foo" => "123"}, %{}, %{}, Router)
      assert %{"href" => "/foo/123"} == body
      assert {"application", "json", %{}} == content_type

    "Bar.action" ->
      {body, content_type, _} = Bar.action([], %{"bar" => "123"}, %{}, %{}, Router)
      assert %{"bar" => "123", "foo" => %{"href" => "/foo/123123"}, "href" => "/bar/123"} == body
      assert {"application", "json", %{}} == content_type

    "Bar.affordance" ->
      {body, content_type} = Bar.affordance([], %{"bar" => "123"}, %{}, %{}, Router)
      assert %{"action" => "/bar/123", "method" => "POST", "input" => %{}} = body
      assert {"application", "json", %{}} == content_type

    "Bar.action missing router" ->
      assert_raise Mazurka.MissingRouterException, fn ->
        Bar.action([], %{"bar" => "123"}, %{}, %{})
      end

    "Bar.affordance missing router" ->
      assert_raise Mazurka.MissingRouterException, fn ->
        Bar.affordance([], %{"bar" => "123"}, %{}, %{})
      end
  end

  context MissingParam do
    resource Foo do
      param foo

      mediatype Hyper do
        action do
          %{}
        end
      end
    end

    resource Bar do
      mediatype Hyper do
        action do
          %{
            "foo" => link_to(Foo)
          }
        end
      end
    end
  after
    "Bar.action" ->
      assert_raise Mazurka.MissingParametersException, fn ->
        Bar.action([], %{}, %{}, %{})
      end
  end

  context NilParam do
    resource Foo do
      param foo

      mediatype Hyper do
        action do
          %{}
        end
      end
    end

    resource Bar do
      mediatype Hyper do
        action do
          %{
            "foo" => link_to(Foo, foo: nil)
          }
        end
      end
    end
  after
    "Bar.action" ->
      {res, _, _} = Bar.action([], %{}, %{}, %{})
      assert %{"foo" => %Mazurka.Affordance.Undefined{resource: Foo}} = res
  end

  context Transition do
    resource Foo do
      param foo

      mediatype Hyper do
        action do
          %{}
        end
      end
    end

    resource Bar do
      mediatype Hyper do
        action do
          transition_to(Foo, foo: "123")
        end
      end
    end

    router Router do
      route "GET", ["foo", :foo], Foo
      route "POST", ["bar"], Bar
    end
  after
    "Foo.action" ->
      {_, _, conn} = Bar.action([], %{}, %{}, %{private: %{}}, Router)
      affordance = conn.private.mazurka_transition
      assert Foo = affordance.resource
      assert %{"foo" => "123"} == affordance.params
  end

  context Invaldation do
    resource Foo do
      param foo

      mediatype Hyper do
        action do
          %{}
        end
      end
    end

    resource Bar do
      param bar

      mediatype Hyper do
        action do
          %{}
        end
      end
    end

    resource Baz do
      mediatype Hyper do
        action do
          invalidates(Foo, foo: "123")
          invalidates(Bar, bar: "456")
        end
      end
    end

    router Router do
      route "GET", ["foo", :foo], Foo
      route "GET", ["bar", :bar], Bar
      route "GET", ["baz", :baz], Baz
    end
  after
    "Baz.action" ->
      {_, _, conn} = Baz.action([], %{}, %{}, %{private: %{}}, Router)
      [second, first] = conn.private.mazurka_invalidations
      assert Foo = first.resource
      assert %{"foo" => "123"} = first.params
      assert Bar = second.resource
      assert %{"bar" => "456"} = second.params
  end
end

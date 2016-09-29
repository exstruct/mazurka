defmodule Test.Mazurka.Resource.Event do
  use Test.Mazurka.Case

  context Single do
    defmodule Foo do
      use Mazurka.Resource

      mediatype Hyper do
        action do
          %{"hello" => "bar"}
        end
      end

      event do
        conn = Map.put(conn, :foo, :bar)
      end
    end
  after
    "action" ->
      {_, _, conn} = Foo.action([], %{}, %{}, %{})
      assert conn[:foo] == :bar
  end

  context Multiple do
    defmodule Foo do
      use Mazurka.Resource

      mediatype Hyper do
        action do
          %{"hello" => "world"}
        end
      end

      event do
        conn = Map.put_new(conn, :foo, :bar)
      end

      event do
        conn = Map.put_new(conn, :foo, :baz)
      end
    end
  after
    "action" ->
      {_, _, conn} = Foo.action([], %{}, %{}, %{})
      assert conn[:foo] == :bar
  end

  context Action do
    defmodule Foo do
      use Mazurka.Resource

      mediatype Hyper do
        action do
          %{"hello" => "world"}
        end
      end

      event do
        conn = Map.put(conn, :hello, action["hello"])
      end
    end
  after
    "action" ->
      {_, _, conn} = Foo.action([], %{}, %{}, %{})
      assert conn[:hello] == "world"
  end

  context "Event with Let Scoping" do
    defmodule Foo do
      use Mazurka.Resource

      let foo = 123

      mediatype Hyper do
        action do
          %{"hello" => "world"}
        end
      end

      event do
        conn = Map.put(conn, :hello, foo + foo)
      end
    end
  after
    "action" ->
      {_, _, conn} = Foo.action([], %{}, %{}, %{})
      assert conn[:hello] == 246
  end
end

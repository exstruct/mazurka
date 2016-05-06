defmodule Test.Mazurka.Resource.Event do
  use Test.Mazurka.Case

  context Single do
    resource Foo do
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
    resource Foo do
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
    resource Foo do
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
end

defmodule Test.Mazurka.Resource.Input do
  use Test.Mazurka.Case

  context Single do
    resource Foo do
      input foo

      mediatype Hyper do
        action do
          %{"foo" => foo}
        end
      end
    end
  after
    "action" ->
      {body, content_type, _} = Foo.action([], %{}, %{"foo" => "123"}, %{})
      assert %{"foo" => "123"} == body
      assert {"application", "json", %{}} = content_type

    "action missing param" ->
      {body, _, _} = Foo.action([], %{}, %{}, %{})
      assert %{"foo" => nil} = body
  end

  context Transform do
    resource Foo do
      input foo do
        [&value, &value]
      end

      input bar, [&value, &value]

      mediatype Hyper do
        action do
          %{
            "bar" => bar,
            "foo" => foo
          }
        end
      end
    end
  after
    "action" ->
      {body, _, _} = Foo.action([], %{}, %{"foo" => "123", "bar" => "456"}, %{})
      assert %{"bar" => ["456", "456"], "foo" => ["123", "123"]} = body
  end

  context Referential do
    resource Foo do
      input foo

      input bar do
        [foo, &value]
      end

      mediatype Hyper do
        action do
          %{
            "bar" => bar
          }
        end
      end
    end
  after
    "action" ->
      {body, _, _} = Foo.action([], %{}, %{"foo" => "123", "bar" => "456"}, %{})
      assert %{"bar" => ["123", "456"]} = body
  end
end

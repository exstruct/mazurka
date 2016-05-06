defmodule Test.Mazurka.Resource.ContentType do
  use Test.Mazurka.Case

  context Multiple do
    resource Foo do
      mediatype Hyper do
        action do
          %{"hello" => "World"}
        end
      end

      mediatype HTML do
        action do
          {"html", nil, []}
        end
      end
    end
  after
    "application/json" ->
      {_, content_type, _} = Foo.action([{"application", "hyper+json", %{}}], %{}, %{}, %{})
      assert {"application", "hyper+json", %{}} = content_type

    "text/html" ->
      {_, content_type, _} = Foo.action([{"text", "html", %{}}], %{}, %{}, %{})
      assert {"text", "html", %{}} = content_type

    "application/*" ->
      {_, content_type, _} = Foo.action([{"application", "*", %{}}], %{}, %{}, %{})
      assert {"application", "json", %{}} = content_type

    "*/html" ->
      {_, content_type, _} = Foo.action([{"*", "html", %{}}], %{}, %{}, %{})
      assert {"text", "html", %{}} = content_type

    "*/*" ->
      {_, content_type, _} = Foo.action([{"*", "*", %{}}], %{}, %{}, %{})
      assert {"application", "json", %{}} = content_type

    "foo/bar, application/json" ->
      {_, content_type, _} = Foo.action([{"foo", "bar", %{}}, {"application", "json", %{}}], %{}, %{}, %{})
      assert {"application", "json", %{}} = content_type

    "text/plain" ->
      assert_raise Mazurka.UnacceptableContentTypeException, fn ->
        Foo.action([{"text", "plain", %{}}], %{}, %{}, %{})
      end
  end

  context TextRequest do
    resource Foo do
      mediatype Text do
        action do
          "Hello, World!"
        end
      end
    end
  after
    "action" ->
      {res, _, _} = Foo.action([], %{}, %{}, %{})
      assert "Hello, World!" = res
  end

  context XMLRequest do
    resource Foo do
      mediatype XML do
        action do
          {"foo", %{}, []}
        end
      end
    end
  after
    "action" ->
      {res, _, _} = Foo.action([], %{}, %{}, %{})
      assert {"foo", %{}, []} = res
  end

  test "throws an error with an undefined mediatype" do
    assert_raise Mazurka.UndefinedMediatype, fn ->
      defmodule Foo do
        use Mazurka.Resource

        mediatype FooBarBaz do
          action do
            %{}
          end
        end
      end
    end
  end

  #context Params do
  #  resource Foo do
  #    mediatype Hyper do
  #      provides "application/hyper+json; foo=bar"
  #
  #      action do
  #        %{"foo" => "bar"}
  #      end
  #    end
  #
  #    mediatype Hyper do
  #      action do
  #        %{"foo" => "baz"}
  #      end
  #    end
  # end
  #after
  #  "Foo.action (foo=bar)" ->
  #    {_, content_type, _} = Foo.action([{"application", "hyper+json", %{"foo" => "bar"}}], %{}, %{}, %{})
  #    assert {"application", "hyper+json", %{"foo" => "bar"}} = content_type
  #
  #  "Foo.action (foo=baz)" ->
  #    {_, content_type, _} = Foo.action([{"application", "hyper+json", %{"foo" => "baz"}}], %{}, %{}, %{})
  #    assert {"application", "hyper+json", %{"foo" => "baz"}} = content_type
  #end
end

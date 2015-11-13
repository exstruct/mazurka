defmodule MazurkaTest.Resources.Partials do
  use Mazurka.Resource

  param name

  condition %MazurkaTest.Partials.Dynamic.can_do_it?{name: name}

  mediatype Hyperjson do
    action do
      %{
        "message" => %MazurkaTest.Partials.Content.message{name: name},
        "direct" => %MazurkaTest.Partials.Dynamic.direct{arg: true},
        "first" => %MazurkaTest.Partials.Dynamic.first{arg: 1},
        "first_with_append" => %MazurkaTest.Partials.Dynamic.first_with_append{arg: 1111},
        "second" => %MazurkaTest.Partials.Dynamic.second{arg: 2},
        "second_with_append" => %MazurkaTest.Partials.Dynamic.second_with_append{arg: 2222},
        "dispatched" => DynamicPartials.first(arg: "dispatched")
      }
    end
  end

  test "should work" do
    conn = request do
      params %{"name" => "Joe"}
    end

    assert conn.status == 200
    resp = Poison.decode!(conn.resp_body)
    assert resp["message"] == "Hello, Joe"
    assert resp["direct"] == "direct called with arg=true, outside=needs_unquoting"
    assert resp["first"] == "first called with arg=1"
    assert resp["first_with_append"] == "first_with_append called with arg=1111"
    assert resp["second"] == "second called with arg=2"
    assert resp["second_with_append"] == "second_with_append called with arg=2222"
    assert resp["dispatched"] == "first called with arg=dispatched"
  end

  test "should fail due to condition" do
    conn = request do
      params %{"name" => "Jane"}
    end

    assert conn.status != 200
    assert conn.private.mazurka_error == true
  end
end

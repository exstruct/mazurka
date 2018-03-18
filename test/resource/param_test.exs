defmodule Test.Mazurka.Param do
  use Test.Mazurka.Case
  import Mazurka.Resource.Param
  import Plug.Test

  block """
  # Param
  """

  describe "param/1" do
    test "success" do
      conn =
        conn(:get, "/")
        |> Map.put(:path_params, %{foo: 123})

      param(:foo)
      _ = conn

      assert foo == 123
    end

    test "failure" do
      conn =
        conn(:get, "/")
        |> Map.put(:path_params, %{foo: 123})

      assert_raise(KeyError, fn ->
        param(:bar)
        _ = conn
        _ = bar
      end)
    end
  end

  describe "param/2" do
    test "success (conn)" do
      conn(:get, "/")
      |> Map.put(:path_params, %{foo: 123})
      |> param(:foo)

      assert foo == 123
    end

    test "success (raise: false)" do
      conn = conn(:get, "/")

      param(:bar, raise: false)
      _ = conn

      assert bar == nil
    end

    test "success (capture arity 1 transform)" do
      conn =
        conn(:get, "/")
        |> Map.put(:path_params, %{foo: 123})

      param(:foo, &is_number/1)
      _ = conn

      assert foo == true
    end

    test "success (capture arity 2 transform)" do
      conn =
        conn(:get, "/")
        |> Map.put(:path_params, %{foo: 123})

      param(:foo, &success_transform/2)
      _ = conn

      assert foo == 246
    end

    defp success_transform(value, conn) do
      {value + value, conn}
    end

    test "success (partial arity 2 transform)" do
      conn =
        conn(:get, "/")
        |> Map.put(:path_params, %{foo: 123})

      param(:foo, &{&1 + &1, &2})
      _ = conn

      assert foo == 246
    end

    test "success (fn arity 1 transform)" do
      conn =
        conn(:get, "/")
        |> Map.put(:path_params, %{foo: 123})

      param(:foo, fn value ->
        value * 2
      end)

      _ = conn

      assert foo == 246
    end

    test "success (fn arity 2 transform)" do
      conn =
        conn(:get, "/")
        |> Map.put(:path_params, %{foo: 123})

      param(:foo, fn value, conn ->
        {value * 2, conn}
      end)

      _ = conn

      assert foo == 246
    end

    test "failure (opts)" do
      conn =
        conn(:get, "/")
        |> Map.put(:path_params, %{foo: 123})

      assert_raise(ArgumentError, fn ->
        param(:bar, raise: %ArgumentError{message: "No Bar"})
        _ = conn
        _ = bar
      end)
    end
  end

  describe "param/3" do
    test "success (as)" do
      conn =
        conn(:get, "/")
        |> Map.put(:path_params, %{foo: 123})

      param(:foo, [as: :bar], &{&1, &2})

      _ = conn

      assert bar == 123
    end

    test "success (conn, transform)" do
      conn(:get, "/")
      |> Map.put(:path_params, %{foo: 123})
      |> param(:foo, &{&1, &2})

      assert foo == 123
    end

    test "success (conn, opts)" do
      conn(:get, "/")
      |> Map.put(:path_params, %{foo: 123})
      |> param(:bar, raise: false)

      assert bar == nil
    end
  end

  describe "param/4" do
    test "success" do
      conn(:get, "/")
      |> Map.put(:path_params, %{foo: 123})
      |> param(:foo, [as: :bar], &is_number/1)

      assert bar == true
    end
  end
end

defmodule Test.Mazurka.Condition do
  use Test.Mazurka.Case
  import Mazurka.Resource.Condition
  import Plug.Test

  block """
  # Condition
  """

  describe "condition/1" do
    test "success (block)" do
      conn = conn(:get, "/")

      condition do
        true
      end

      assert conn.method == "GET"
    end

    test "success (capture)" do
      conn = conn(:get, "/")

      condition &is_map/1

      assert conn.method == "GET"
    end

    test "success (partial)" do
      conn = conn(:get, "/")

      condition &(&1.path_info == [])

      assert conn.method == "GET"
    end

    test "success (anonymous)" do
      conn = conn(:get, "/")

      condition fn %{path_info: path_info} ->
        path_info == []
      end

      assert conn.method == "GET"
    end

    test "failure (false)" do
      conn = conn(:get, "/")

      assert_raise(Mazurka.ConditionError, fn ->
        condition do
          false
        end

        _ = conn
      end)
    end

    test "failure (nil)" do
      conn = conn(:get, "/")

      assert_raise(Mazurka.ConditionError, fn ->
        condition do
          nil
        end

        _ = conn
      end)
    end

    test "failure (invalid value)" do
      conn = conn(:get, "/")

      assert_raise(BadBooleanError, fn ->
        condition do
          :foo
        end

        _ = conn
      end)
    end

    test "failure (affordance)" do
      conn =
        conn(:get, "/")
        |> Plug.Conn.put_private(:mazurka_affordance, true)

      assert_raise(Mazurka.AffordanceError, fn ->
        condition do
          false
        end

        _ = conn
      end)
    end
  end

  describe "condition/2" do
    test "success (with conn)" do
      conn =
        conn(:get, "/")
        |> condition do
          conn.path_info == []
        end

      assert conn.method == "GET"
    end

    test "success (with opts)" do
      conn = conn(:get, "/")

      condition [] do
        true
      end

      assert conn.method == "GET"
    end

    test "failure (with conn)" do
      assert_raise(Mazurka.ConditionError, fn ->
        conn(:get, "/")
        |> condition do
          false
        end
      end)
    end

    test "failure (with opts)" do
      conn = conn(:get, "/")

      assert_raise(ArgumentError, fn ->
        condition raise: ArgumentError do
          false
        end

        _ = conn
      end)
    end
  end

  describe "condition/3" do
    test "success" do
      conn =
        conn(:get, "/")
        |> condition [] do
          true
        end

      assert conn.method == "GET"
    end

    test "failure" do
      assert_raise(ArgumentError, fn ->
        conn(:get, "/")
        |> condition raise: %ArgumentError{message: "FAIL"} do
          false
        end
      end)
    end
  end
end

defmodule MazurkaTest do
  use ExUnit.Case

  test "the truth" do
    conn = %{private: %{mazurka_router: MazurkaTest.Router}}
    {out, state} = MazurkaTest.Resources.Root.action(conn, fn(mod, fun, args, _, _, _, _) ->
      IO.inspect {mod, fun, args}
      {:ok, "123"}
    end)
    Poison.encode!(out)
    |> IO.puts
  end
end

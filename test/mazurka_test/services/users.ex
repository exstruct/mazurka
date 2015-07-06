defmodule MazurkaTest.Services.Users do
  def list(_env) do
    {:ok, [
      "1",
      "2",
      "3",
      "4",
      "5"
    ]}
  end

  def get(_id, _env) do
    {:ok, %{}}
  end

  def update(_id, _params, _env) do
    {:ok, true}
  end
end
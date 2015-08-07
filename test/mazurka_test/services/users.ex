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

  def get(id, _env) when id in ["1", "2", "3", "4", "5", "6"] do
    {:ok, %{}}
  end
  def get(_id, _) do
    {:error, :not_found}
  end

  def update(_id, _params, _env) do
    {:ok, true}
  end
end

defmodule MazurkaTest.Services.Users do
  defstruct id: nil,
            created_at: nil,
            display_name: nil,
            nickname: nil,
            __status__: :unfetched

  def list(_env) do
    users = 1..5
    |> Enum.map(&(%__MODULE__{id: to_string(&1)}))
    {:ok, users}
  end

  def get(id, _env) when id in ["1", "2", "3", "4", "5", "6"] do
    {:ok, %__MODULE__{id: id}}
  end
  # TODO fix etude error
  # def get(id, _) do
  #   {:ok, %__MODULE__{id: id}}
  # end
  def get(_, _) do
    {:error, :not_found}
  end

  def update(_id, _params, _env) do
    {:ok, true}
  end
end

defimpl Etude.Dict, for: MazurkaTest.Services.Users do
  use Etude.Dict

  def cache_key(dict) do
    {MazurkaTest.Services.Users, dict.id}
  end

  keys = %MazurkaTest.Services.Users{} |> Map.delete(:id) |> Map.keys

  def fetch(dict = %{id: id}, :id, _) do
    {:ok, id, dict}
  end
  def fetch(dict = %{id: id, __status__: :unfetched}, key, ref) when key in unquote(keys) do
    pid = Etude.Async.spawn(ref, fn ->
      case id do
        "1" ->
          {:ok, %{display_name: "Robert", __status__: :fetched}}
        "2" ->
          {:ok, %{display_name: "Joe", __status__: :fetched}}
        "3" ->
          {:ok, %{display_name: "Mike", __status__: :fetched}}
        "4" ->
          {:ok, %{display_name: "Jose", __status__: :fetched}}
        "5" ->
          {:ok, %{display_name: "Fred", __status__: :fetched}}
        "6" ->
          {:ok, %{display_name: "Scott", __status__: :fetched}}
        _ ->
          # TODO fix etude error
          # {:error, :not_found}
          :erlang.error(:not_found)
      end
    end)
    {:pending, pid, %{dict | __status__: :fetching}}
  end
  def fetch(dict = %{__status__: :fetching}, key, _ref) when key in unquote(keys) do
    {:pending, dict}
  end
  def fetch(dict = %{__status__: :fetched}, key, _ref) do
    {:ok, Map.get(dict, key), dict}
  end
end

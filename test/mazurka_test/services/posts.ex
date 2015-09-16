defmodule MazurkaTest.Services.Posts do
  use Mazurka.Model

  schema "posts" do
    field :title, :string
  end

  relation comments do
    {:ok, [1,2,3]}
  end

  def get(id) do
    {:ok, %__MODULE__{id: id}}
  end
end

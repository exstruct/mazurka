defmodule Mazurka.Resource.Input do
  @doc false
  def format({{:., _, [{:__aliases__, _, [:Input]}, :get]}, _, []}, type) do
    get(type)
  end
  def format({{:., _, [input, :get]}, _, []}, type) when input in [:Input, Elixir.Input, __MODULE__] do
    get(type)
  end
  def format({{:., _, [{:__aliases__, _, [:Input]}, :get]}, _, [name]}, type) do
    get(type, name)
  end
  def format({{:., _, [input, :get]}, _, [name]}, type) when input in [:Input, Elixir.Input, __MODULE__] do
    get(type, name)
  end
  def format(other, _) do
    other
  end

  defp get(:prop) do
    {:etude_prop, [], [:query]}
  end
  defp get(:conn) do
    quote do
      ^^Mazurka.Resource.Input.get()
    end
  end
  defp get(:prop, name) do
    quote do
      ^Mazurka.Runtime.get_param(unquote(get(:prop)), unquote(name))
    end
  end
  defp get(:conn, name) do
    quote do
      ^^Mazurka.Resource.Input.get(unquote(name))
    end
  end

  @doc false
  def get([], conn, _, _, _) do
    conn = Plug.Conn.fetch_query_params(conn)
    {:ok, conn.params, conn}
  end
  def get([name], conn, _, _, _) do
    conn = Plug.Conn.fetch_query_params(conn)
    value = Dict.get(conn.params, name)
    normalized = if value == nil, do: :undefined, else: value
    {:ok, normalized, conn}
  end
end

defmodule Mazurka.Runtime do
  def raise([exception], _conn, _parent, _ref, _attrs) do
    {:error, exception}
  end

  def put_status([status], conn, _parent, _ref, _attrs) do
    ## TODO potentially add support for more than just HTTP statuses
    status = Plug.Conn.Status.code(status)
    {:ok, status, %{conn | status: status}}
  end

  def get_mediatype(context) do
    Dict.get(context.private, :mazurka_mediatype, {nil, nil, nil})
  end

  def put_mediatype(%{private: private} = context, module, value) do
    private = private
    |> Dict.put(:mazurka_mediatype, value)
    |> Dict.put(:mazurka_mediatype_handler, module)
    %{context | private: private}
  end

  def get_param(list, name) when is_list(list) do
    name_s = name |> to_string()
    name_a = name |> String.to_existing_atom()
    find_key(list, name, name_s, name_a)
  end
  def get_param(map, name) when is_map(map) do
    map
    |> :maps.to_list()
    |> get_param(name)
  end
  def get_param(params, _) when params in [nil, :undefined] do
    :undefined
  end

  defp find_key([], _, _, _) do
    :undefined
  end
  defp find_key([{key, value} | _], name, name_s, name_a) when key in [name, name_s, name_a] do
    value
  end
  defp find_key([_ | rest], name, name_s, name_a) do
    find_key(rest, name, name_s, name_a)
  end
end

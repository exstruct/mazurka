defmodule Mazurka.Runtime do

  def raise([exception], _conn, _parent, _ref, _attrs) do
    {:error, exception}
  end

  def not(:undefined), do: true
  def not(nil), do: true
  def not(false), do: true
  def not(_), do: false

  def apply(falsy, _, _) when falsy == nil or falsy == :undefined do
    falsy
  end
  def apply(map, prop, []) when is_map(map) do
    Dict.get(map, prop)
  rescue
    e in UndefinedFunctionError ->
      case e do
        %{arity: 3, function: :get} ->
          Map.get(map, prop)
        _ ->
          raise e
      end
  end
  def apply(module, prop, args) when is_atom(module) do
    :erlang.apply(module, prop, args)
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
end

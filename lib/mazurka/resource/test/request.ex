defmodule Mazurka.Resource.Test.Request do
  defmacro request() do
    quote do
      Mazurka.Resource.Test.Request.request([do: nil])
    end
  end

  defmacro request([do: block]) do
    quote do
      require Mazurka.Protocol.Request
      Mazurka.Protocol.Request.request __MODULE__ do
        import Mazurka.Protocol.Request
        import unquote(__MODULE__)

        # Clear the path info so the router can resolve the path
        var!(conn) = %{var!(conn) | request_path: nil, path_info: nil}

        unquote(block)
      end
    end
  end

  defmacro authenticate_as(user_id, client_id \\ nil) do
    quote do
      {name, value} = var!(__router__).authenticate_as(unquote(user_id), unquote(client_id))
      header(name, value)
    end
  end
end

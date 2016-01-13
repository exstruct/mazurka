defmodule Mazurka.Protocol.HTTP.Request do
  defmacro __using__(_) do
    quote do
      @doc """
      Make a request to the router

          conn = request do
            get "/"
            accept "hyper+json"
            header "x-orig-host", "example.com"
          end
      """
      defmacro request(resource \\ nil, block) do
        quote do
          require Mazurka.Protocol.Request
          import Mazurka.Protocol.HTTP.Request
          import unquote(__MODULE__)

          unquote(resource)
          |> Mazurka.Protocol.Request.request(unquote(block))
          |> unquote(__MODULE__).call([])
          |> Mazurka.Protocol.Request.merge_resp()
        end
      end
    end
  end

  for method <- [:get, :post, :put, :patch, :delete, :options, :head] do
    defmacro unquote(method)(path) do
      method = unquote(method)
      quote do
        method(unquote(method))
        path(unquote(path))
      end
    end
  end
end

defmodule Mazurka.Resource.Test.Seed do
  defmacro seed(module, params \\ Macro.escape(%{})) do
    fake_conn = %Plug.Conn{private: %{}} |> Macro.escape()
    quote do
      ## TODO support async etude calls
      case var!(__router__).dispatch(unquote(module), :seed, [unquote(params)], unquote(fake_conn), nil, nil, nil) do
        {:ok, value} ->
          value
      end
    end
  end
end

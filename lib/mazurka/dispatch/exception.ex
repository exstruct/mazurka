defmodule Mazurka.Dispatch.Exception do
  defexception [:module, :function, :arity, :dispatch, self: false]

  env = try do
    Mix.env
  rescue
    _ ->
      :prod
  end

  if env == :dev do
    def message(%{module: module, function: function, arity: arity, dispatch: dispatch} = err) do
      message = UndefinedFunctionError.message(err)

      sample_args = :lists.seq(1, arity)
      |> Enum.map(&("arg_#{&1}"))
      |> Enum.join("\n")

      dispatch_args = :lists.seq(1, arity)
      |> Enum.map(&("&#{&1}"))
      |> Enum.join("\n")

      dispatch = if dispatch do
        inspect(dispatch)
      else
        "your dispatch module"
      end

      target_module = case Module.split(module) do
        [] ->
          "my_api_#{module}"
        parts ->
          ["MyApi" | parts] |> Enum.join(".")
      end

      """
      #{message}

        If you want to bypass #{dispatch} try this instead:

            ^#{inspect(module)}.#{function}(#{sample_args})

        Otherwise you'll need to add the following to #{dispatch}:

            service #{inspect(module)}.#{function}/#{arity}, #{target_module}.#{function}(#{dispatch_args})

        Check out the docs for more information: https://www.mazurka.io/guide/dispatch/overview
      """
    end
  else
    defdelegate message(err), to: UndefinedFunctionError
  end
end

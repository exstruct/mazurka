defmodule Mazurka.Resource.Utils.Check do
  @moduledoc false

  defmacro __using__(_) do
    module = __CALLER__.module
    name = Module.split(module) |> List.last()
    mazurka_check = :"mazurka__#{String.downcase(name)}s"
    macro = :"#{String.downcase(name)}"

    quote bind_quoted: binding, location: :keep do
      use Mazurka.Resource.Utils

      defmacro __using__(_) do
        check = unquote(mazurka_check)
        quote do
          import unquote(__MODULE__)

          @doc false
          defp unquote(check)(unquote_splicing(arguments), _) do
            :ok
          end
          defoverridable [{unquote(check), unquote(length(arguments) + 1)}]
        end
      end

      defmacro unquote(macro)(block, message \\ nil) do
        to_quoted(block, message)
      end

      defp to_quoted([do: block], message) do
        to_quoted(block, message)
      end
      defp to_quoted(block, nil) do
        message = message(block)
        to_quoted(block, message)
      end
      defp to_quoted(block, message) do
        check = unquote(mazurka_check)
        quote location: :keep do
          @doc false
          defp unquote(check)(unquote_splicing(arguments), unquote(scope)) do
            case super(unquote_splicing(arguments), unquote(scope)) do
              :ok ->
                if unquote(block) do
                  :ok
                else
                  {:error, unquote(message)}
                end
              other ->
                other
            end
          end
          defoverridable [{unquote(check), unquote(length(arguments) + 1)}]
        end
      end

      defp message(block) do
        code = Macro.to_string(block)
        "#{unquote(name)} failure of #{inspect(code)}"
      end
    end
  end
end

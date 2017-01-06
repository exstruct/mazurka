defmodule Mazurka.Resource.Utils.Check do
  @moduledoc false

  defmacro __using__(_) do
    module = __CALLER__.module
    name = Module.split(module) |> List.last()
    mazurka_check = :"__mazurka_#{String.downcase(name)}s__"
    macro = :"#{String.downcase(name)}"

    quote bind_quoted: binding(), location: :keep do
      alias Mazurka.Resource.Utils

      defmacro __using__(_) do
        check = unquote(mazurka_check)
        quote do
          import unquote(__MODULE__)

          @doc false
          def unquote(check)(unquote_splicing(Utils.arguments), _) do
            :ok
          end
          defoverridable [{unquote(check), unquote(length(Utils.arguments) + 1)}]
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
          def unquote(check)(unquote_splicing(Utils.arguments), unquote(Utils.scope)) do
            case super(unquote_splicing(Utils.arguments), unquote(Utils.scope)) do
              :ok ->
                Mazurka.Resource.Utils.Scope.dump()
                if unquote(block) do
                  :ok
                else
                  {:error, unquote(message)}
                end
              other ->
                other
            end
          end
          defoverridable [{unquote(check), unquote(length(Utils.arguments) + 1)}]
        end
      end

      defp message(block) do
        code = Macro.to_string(block)
        "#{unquote(name)} failure of #{inspect(code)}"
      end
    end
  end
end

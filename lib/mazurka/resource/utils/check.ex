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

          Module.register_attribute(__MODULE__, unquote(check), accumulate: true)
          @before_compile unquote(__MODULE__)
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
          Module.put_attribute(__MODULE__, unquote(check), {unquote(Macro.escape(block)), unquote(message)})
        end
      end

      defp message(block) do
        code = Macro.to_string(block)
        "#{unquote(name)} failure of #{inspect(code)}"
      end

      defmacro __before_compile__(env) do
        check = unquote(mazurka_check)
        checks = Module.get_attribute(env.module, check)
          |> Enum.reduce(:ok, fn({block, message}, parent) ->
            quote do
              if unquote(block) do
                unquote(parent)
              else
                {:error, unquote(message)}
              end
            end
          end)
        scope = case checks do
          :ok ->
            []
          _ ->
            [quote(do: Mazurka.Resource.Utils.Scope.dump())]
        end
        quote do
          defp unquote(check)(unquote_splicing(Utils.arguments), unquote(Utils.scope)) do
            unquote_splicing(scope)
            unquote(checks)
          end
        end
      end
    end
  end
end

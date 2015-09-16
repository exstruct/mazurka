defmodule Mazurka.Model.Relation do
  defmodule Status do
    defstruct state: :pending
  end
  alias __MODULE__.Status

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  def get(module) do
    Module.get_attribute(module, :mazurka_relations)
  end

  defmacro relation(key, conf \\ [], [do: logic]) do
    key = format_key(key)
    keys = [key, to_string(key)]

    {:__block__, _, clauses} = quote do
      unquote(resolve(keys, conf, logic))
      def fetch(model = %{unquote(key) => %unquote(Status){state: :pending}}, key, _) when key in unquote(keys) do
        {:pending, model}
      end
      def fetch(model = %{unquote(key) => value}, key, _) when key in unquote(keys) do
        {:ok, value, model}
      end
    end

    module = __CALLER__.module
    Module.register_attribute(module, :mazurka_relations, accumulate: true)
    clauses
    |> :lists.reverse()
    |> Enum.map(&(Module.put_attribute(module, :mazurka_relations, &1)))

    Module.put_attribute(module, :struct_fields,
      [{key, %Ecto.Association.NotLoaded{__field__: key,
                                         __owner__: module}}])

    nil
  end

  defp format_key({name, _, _}), do: name
  defp format_key({name, _}), do: name
  defp format_key(name), do: name

  defp resolve(keys = [key | _], conf, logic) do
    if conf[:async] !== false do
      quote do
        def fetch(var!(model) = %{unquote(key) => %Ecto.Association.NotLoaded{}}, key, ref) when key in unquote(keys) do
          pid = Etude.Async.spawn(ref, fn ->
            case unquote(logic) do
              {:ok, relation} ->
                {:ok, %{unquote(key) => relation}}
              error ->
                error
            end
          end)
          {:pending, pid, Map.put(var!(model), unquote(key), %unquote(Status){})}
        end
      end
    else
      quote do
        def fetch(var!(model) = %{unquote(key) => %Ecto.Association.NotLoaded{}}, key, _) when key in unquote(keys) do
          case unquote(logic) do
            {:ok, relation} ->
              {:ok, %{unquote(key) => relation}}
            error ->
              error
          end
        end
      end
    end
  end
end

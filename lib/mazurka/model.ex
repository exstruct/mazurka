defmodule Mazurka.Model do
  @moduledoc """

  """
  defmacro __using__(_) do
    quote do
      use Ecto.Model
      use Mazurka.Model.Relation
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_ENV) do
    module = __CALLER__.module

    relations = Mazurka.Model.Relation.get(module)

    struct_fields = Module.get_attribute(module, :struct_fields)

    fields = format_struct_fields(struct_fields)
    field_vars = format_struct_vars(struct_fields)
    valid_fields = format_valid_fields(struct_fields)

    {primary_key, _, _} = Module.get_attribute(module, :primary_key)

    field_clauses = for field <- valid_fields do
      keys = [field, to_string(field)]
      quote do
        def fetch(model = %{unquote(primary_key) => id, __meta__: %{state: :built, repo: repo, opts: opts} = meta}, key, ref) when key in unquote(keys) do
          pid = Etude.Async.spawn(ref, fn ->
            unquote(field_vars) = repo.get!(unquote(module), id, opts)
            model = Map.put(unquote(field_vars), :__meta__, %{meta | state: :loaded})
            {:ok, model}
          end)
          {:pending, pid, %{model | __meta__: %{meta | state: :loading}}}
        end
        def fetch(model = %{__meta__: %{state: :loading}}, key, _) when key in unquote(keys) do
          {:pending, model}
        end
        def fetch(model = %{__meta__: %{state: :loaded}}, key, ref) when key in unquote(keys) do
          {:ok, Map.get(model, unquote(field)), model}
        end
      end
    end

    quote do
      def get(var!(repo), var!(id), var!(opts)) do
        {:ok, unquote({:%{}, [], [{:__struct__, module} | fields]})}
      end

      defimpl Etude.Dict, for: unquote(module) do
        use Etude.Dict

        def cache_key(%{unquote(primary_key) => id, __meta__: %{repo: repo, opts: opts}}) do
          {repo, unquote(module), to_string(id), :erlang.phash2(opts)}
        end
        def cache_key(%{unquote(primary_key) => id}) do
          {unquote(module), to_string(id)}
        end

        def fetch(model = %{unquote(primary_key) => id}, :id, _) do
          {:ok, id, model}
        end
        unquote_splicing(relations || [])
        unquote_splicing(field_clauses || [])
        def fetch(model, key, _) do
          {:error, model}
        end
      end
    end
  end

  defp format_struct_fields(fields) do
    Enum.reduce(fields, [], fn
      ({:id, _}, acc) ->
        [{:id, Macro.var(:id, nil)} | acc]
      ({_key, %Ecto.Association.NotLoaded{}}, acc) ->
        acc
      ({:__meta__, meta}, acc) ->
        meta = Map.merge(meta, %{
          __struct__: Mazurka.Model.Metadata,
          repo: Macro.var(:repo, nil),
          opts: Macro.var(:opts, nil)
        }) |> Map.to_list
        [{:__meta__, {:%{}, [], meta}} | acc]
      ({key, _}, acc) ->
        [{key, nil} | acc]
    end)
  end

  defp format_valid_fields(fields) do
    Enum.reduce(fields, [], fn
      ({_, %Ecto.Association.NotLoaded{}}, acc) ->
        acc
      ({:__meta__, _}, acc) ->
        acc
      ({key, _}, acc) when is_binary(key) ->
        [String.to_atom(key) | acc]
      ({key, _}, acc) ->
        [key | acc]
    end)
  end

  defp format_struct_vars(fields) do
    {:%{}, [], Enum.reduce(fields, [], fn
      ({_, %Ecto.Association.NotLoaded{}}, acc) ->
        acc
      ({:__meta__, _}, acc) ->
        acc
      ({key, _}, acc) ->
        [{key, Macro.var(key, nil)} | acc]
    end)}
  end
end

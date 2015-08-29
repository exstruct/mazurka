defmodule Mazurka.Model do
  @moduledoc """

  """
  defmacro __using__(_) do
    quote do
      use Ecto.Model
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_ENV) do
    module = __CALLER__.module

    struct_fields = Module.get_attribute(module, :struct_fields)

    fields = format_struct_fields(struct_fields)
    field_vars = format_struct_vars(struct_fields)
    valid_fields = format_valid_fields(struct_fields)
    assoc_fields = format_assoc_fields(struct_fields)

    ## TODO pull in the @primary_key

    quote do
      def get(var!(repo), var!(id), var!(opts) \\ []) do
        {:ok, unquote({:%{}, [], [{:__struct__, module} | fields]})}
      end

      defimpl Etude.Dict, for: unquote(module) do
        use Etude.Dict

        def cache_key(%{id: id, __meta__: %{repo: repo, opts: opts}}) do
          {repo, unquote(module), to_string(id), :erlang.phash2(opts)}
        end

        def fetch(model = %{id: id}, :id, _) do
          {:ok, id, model}
        end
        def fetch(model = %{__meta__: %Ecto.Schema.Metadata{}}, key, _ref) when key in unquote(valid_fields) do
          {:ok, Map.get(model, key), model}
        end
        def fetch(model = %{id: id, __meta__: %{state: :built, repo: repo, opts: opts} = meta}, key, ref) when key in unquote(valid_fields) do
          pid = Etude.Async.spawn(ref, fn ->
            unquote(field_vars) = repo.get!(unquote(module), id, opts)
            model = Map.put(unquote(field_vars), :__meta__, %{meta | state: :loaded})
            {:ok, model}
          end)
          {:pending, pid, %{model | __meta__: %{meta | state: :loading}}}
        end
        def fetch(model = %{__meta__: %{state: :loading}}, key, _) when key in unquote(valid_fields) do
          {:pending, model}
        end
        def fetch(model = %{__meta__: %{state: :loaded}}, key, ref) when key in unquote(valid_fields) do
          {:ok, Map.get(model, key), model}
        end
        unquote_splicing(assoc_fields)
        def fetch(model, _, _) do
          {:error, model}
        end
      end
    end
  end

  defp format_struct_fields(fields) do
    Enum.map(fields, fn
      {:id, _} ->
        {:id, Macro.var(:id, nil)}
      {key, %Ecto.Association.NotLoaded{} = assoc} ->
        {key, Macro.escape(assoc)}
      {:__meta__, meta} ->
        meta = Map.merge(meta, %{
          __struct__: Mazurka.Model.Metadata,
          repo: Macro.var(:repo, nil),
          opts: Macro.var(:opts, nil)
        }) |> Map.to_list
        {:__meta__, {:%{}, [], meta}}
      {key, _} ->
        {key, nil}
    end)
  end

  defp format_valid_fields(fields) do
    Enum.reduce(fields, [], fn
      ({_, %Ecto.Association.NotLoaded{}}, acc) ->
        acc
      ({:__meta__, _}, acc) ->
        acc
      ({key, _}, acc) ->
        [key | acc]
    end)
  end

  defp format_assoc_fields(fields) do
    Enum.reduce(fields, [], fn
      ({key, %Ecto.Association.NotLoaded{} = assoc}, acc) ->
        [format_assoc_field(key, assoc) | acc]
      (_, acc) ->
        acc
    end)
  end

  defp format_assoc_field(key, _assoc) do
    ## TODO
    quote do
      def fetch(model = %{unquote(key) => %Ecto.Association.NotLoaded{}}, unquote(key), ref) do
        # TODO: add error handling
        {:ok, model.__meta__.repo.all(assoc(model, unquote(key))), model}
      end
      def fetch(model = %{unquote(key) => %{__struct__: Mazurka.Model.Association.Loading}}, unquote(key), _) do
        {:pending, model}
      end
      def fetch(model = %{unquote(key) => value}, unquote(key), _) do
        {:ok, value, model}
      end
     end
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

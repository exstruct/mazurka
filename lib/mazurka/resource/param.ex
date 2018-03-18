defmodule Mazurka.Resource.Param do
  @moduledoc false

  defmacro __using__(_) do
    Module.register_attribute(__CALLER__.module, :mazurka_params, accumulate: true)

    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro param(name) when is_atom(name) do
    param_body(name, nil, [], nil, __CALLER__)
  end

  defmacro param(name, opts) when is_atom(name) and is_list(opts) do
    param_body(name, nil, opts, nil, __CALLER__)
  end

  defmacro param(name, transform) when is_atom(name) do
    param_body(name, nil, [], transform, __CALLER__)
  end

  defmacro param(conn, name) when is_atom(name) do
    param_body(name, conn, [], nil, __CALLER__)
  end

  defmacro param(name, opts, transform) when is_atom(name) and is_list(opts) do
    param_body(name, nil, opts, transform, __CALLER__)
  end

  defmacro param(conn, name, opts) when is_atom(name) and is_list(opts) do
    param_body(name, conn, opts, nil, __CALLER__)
  end

  defmacro param(conn, name, transform) when is_atom(name) do
    param_body(name, conn, [], transform, __CALLER__)
  end

  defmacro param(conn, name, opts, transform) when is_atom(name) and is_list(opts) do
    param_body(name, conn, opts, transform, __CALLER__)
  end

  defp param_body(var, conn, opts, transform, env) do
    var = {name, _, _} = format_var(var)
    value = Macro.var(:"@mazurka_param", __MODULE__)
    v_conn = Macro.var(:conn, __MODULE__)
    body = compile_transform(value, v_conn, transform)

    # TODO only set if available
    %{module: module} = env
    doc = opts[:doc]
    Module.put_attribute(module, :mazurka_params, {name, doc})

    quote do
      unquote(v_conn) = %{path_params: path_params} = unquote(conn || Macro.var(:conn, nil))
      unquote(value) = unquote(compile_fetch(name, opts[:raise]))
      {unquote(format_var(opts[:as] || var)), conn} = unquote(body)
      conn
    end
    |> maybe_assign(conn)
  end

  defp compile_transform(value, conn, nil) do
    {:{}, [], [value, conn]}
  end

  defp compile_transform(value, conn, {:&, _, [{:/, meta, [{call, _, _}, arity]}]}) do
    case arity do
      1 ->
        {:{}, meta, [{call, meta, [value]}, conn]}

      2 ->
        {call, meta, [value, conn]}
    end
  end

  # TODO inspect the arity of the function
  defp compile_transform(value, conn, {:&, _, _} = fun) do
    {{:., [], [fun]}, [], [value, conn]}
  end

  defp compile_transform(value, conn, {:fn, _, clauses}) do
    clauses
    |> Enum.map_reduce(nil, fn
      {:->, meta, [[v, c], body]}, arity when arity === 2 or arity === nil ->
        {{:->, meta, [[{:{}, [], [v, c]}], body]}, 2}

      {:->, meta, [[v], body]}, arity when arity === 1 or arity === nil ->
        {{:->, meta, [[v], {:{}, [], [body, conn]}]}, 1}

      _, _ ->
        raise "Incompatible arities"
    end)
    |> case do
      {clauses, 1} ->
        quote do
          case unquote(value), do: unquote(clauses)
        end

      {clauses, 2} ->
        quote do
          case {unquote(value), unquote(conn)}, do: unquote(clauses)
        end
    end
  end

  defp compile_fetch(name, nil) do
    quote do
      Map.fetch!(path_params, unquote(name))
    end
  end

  defp compile_fetch(name, false) do
    quote do
      Map.get(path_params, unquote(name))
    end
  end

  defp compile_fetch(name, {:%, _, _} = error) do
    quote do
      case Map.fetch(path_params, unquote(name)) do
        {:ok, value} ->
          value

        _ ->
          raise unquote(error)
      end
    end
  end

  defp maybe_assign(body, nil) do
    quote do
      unquote(Macro.var(:conn, nil)) = unquote(body)
    end
  end

  defp maybe_assign(body, _) do
    body
  end

  defp format_var({name, _, context} = var) when is_atom(name) and is_atom(context) do
    var
  end

  defp format_var(name) when is_atom(name) do
    Macro.var(name, nil)
  end
end

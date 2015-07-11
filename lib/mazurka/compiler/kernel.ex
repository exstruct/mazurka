defmodule Mazurka.Compiler.Kernel do
  def wrap(block) do
    input = {:__aliases__, [alias: false], [:Mazurka, :Runtime, :Input]}
    {:__block__, [],
     [{:import, [],
       [{:__aliases__, [alias: false], [:Kernel]}, [only: [], warn: false]]},
      {:import, [],
       [{:__aliases__, [alias: false], [:Mazurka, :Compiler, :Kernel]}, [warn: false]]},
      {:alias, [], [input, [warn: false]]},
      block]}
  end

  defmacro prop(name) when is_atom(name) do
    {:etude_prop, [], [name]}
  end

  defmacro link_to(resource, params \\ nil, query \\ nil, fragment \\ nil) do
    link(__CALLER__, :link_to, resource, params, query, fragment)
  end

  defmacro transition_to(resource, params \\ nil, query \\ nil, fragment \\ nil) do
    link(__CALLER__, :transition_to, resource, params, query, fragment)
  end

  defp link(caller, function, resource, params, query, fragment) do
    [parent_module] = caller.context_modules
    parent = %{caller | module: parent_module}
    resource_name = Macro.expand(resource, parent)
    Mazurka.Compiler.Utils.put(parent, nil, Mazurka.Resource.Link, resource_name, params)
    params = Mazurka.Resource.Link.format_params(params)
    quote do
      ^^Mazurka.Resource.Link.unquote(function)(unquote(resource_name), unquote(params), unquote(query), unquote(fragment))
    end
  end

  defmacro if(expression, arms) do
    {:etude_cond, [], [expression, arms]}
  end

  defmacro raise(expression) do
    quote do
      ^^Mazurka.Runtime.raise(unquote(expression))
    end
  end

  defmacro left |> right do
    [{h, _}|t] = Macro.unpipe({:|>, [], [left, right]})
    :lists.foldl(fn
      ({{:^, meta, [x]}, pos}, acc) ->
        {:^, meta, [Macro.pipe(acc, x, pos)]}
      ({x, pos}, acc) ->
        Macro.pipe(acc, x, pos)
    end, h, t)
  end

  defmacro lhs || rhs do
    {:etude_cond, [], [lhs, [do: lhs, else: rhs]]}
  end

  defmacro left or right do
    {:etude_cond, [], [left, [do: left, else: right]]}
  end

  defmacro left and right do
    {:etude_cond, [], [left, [do: right, else: false]]}
  end

  defmacro left &&& right do
    {:etude_cond, [], [left, [do: right, else: :undefined]]}
  end

  ## TODO implement the rest of these
end
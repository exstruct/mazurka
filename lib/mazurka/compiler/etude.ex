defmodule Mazurka.Compiler.Etude do
  alias Etude.Node

  def elixir_to_etude(ast, module) do
    ## TODO prewalk and check for defined functions
    {etude_ast, _acc} = Macro.postwalk(ast, %{module: module}, fn(node, acc) ->
      {out, acc} = handle_node(node, acc)
      {out, acc}
    end)
    etude_ast
  end

  # bif
  defp handle_node({:=, meta, [%Node.Var{name: name}]}, acc) do
    {%Node.Assign{name: name,
                  expression: nil,
                  line: meta[:line]}, acc}
  end
  defp handle_node({:=, meta, [%Node.Var{name: name}, rhs]}, acc) do
    {%Node.Assign{name: name,
                  expression: rhs,
                  line: meta[:line]}, acc}
  end
  defp handle_node({:=, meta, [lhs, rhs]}, acc) do
    {%Node.Assign{name: lhs,
                  expression: rhs,
                  line: meta[:line]}, acc}
  end
  defp handle_node({:^, _, [%Node.Call{attrs: %{native: true} = attrs} = call]}, acc) do
    attrs = Dict.put(attrs, :native, :hybrid)
    {%{call | attrs: attrs}, acc}
  end
  defp handle_node({:^, _, [%Node.Call{attrs: attrs} = call]}, acc) do
    attrs = Dict.put(attrs, :native, true)
    {%{call | attrs: attrs}, acc}
  end
  ## comprehensions
  defp handle_node({:<-, meta, [%Node.Var{name: value, line: value_line}, collection]}, acc) do
    {%Node.Comprehension{collection: collection,
                         value: %Node.Assign{name: value, line: value_line},
                         type: :list,
                         line: meta[:line]}, acc}
  end
  defp handle_node({:<-, meta, [{%Node.Var{name: key, line: key_line}, %Node.Var{name: value, line: value_line}}, collection]}, acc) do
    {%Node.Comprehension{collection: collection,
                         key: %Node.Assign{name: key, line: key_line},
                         value: %Node.Assign{name: value, line: value_line},
                         type: :list,
                         line: meta[:line]}, acc}
  end
  defp handle_node({:for, _, [%Node.Comprehension{} = comprehension, expression]}, acc) do
    comprehension = %{comprehension | expression: expression}
    {comprehension, acc}
  end
  defp handle_node({:_, meta, _}, acc) do
    {%Node.Var.Wildcard{line: meta[:line]}, acc}
  end
  defp handle_node({:etude_cond, meta, [expression, arm]}, acc) when not is_list(arm) do
    handle_node({:etude_cond, meta, [expression, [arm, nil]]}, acc)
  end
  defp handle_node({:etude_cond, meta, [expression, [{:do, arm1}, arm2]]}, acc) do
    handle_node({:etude_cond, meta, [expression, [arm1, arm2]]}, acc)
  end
  defp handle_node({:etude_cond, meta, [expression, [arm1, {:else, arm2}]]}, acc) do
    handle_node({:etude_cond, meta, [expression, [arm1, arm2]]}, acc)
  end
  defp handle_node({:etude_cond, meta, [expression, [arm1, arm2]]}, acc) do
    {%Node.Cond{expression: expression,
                arms: [arm1, arm2],
                line: meta[:line]}, acc}
  end
  defp handle_node({:etude_prop, meta, [name]}, acc) do
    {%Node.Prop{name: name,
                line: meta[:line]}, acc}
  end
  # atom
  defp handle_node(atom, acc) when is_atom(atom) do
    {atom, acc}
  end
  # binary
  defp handle_node(binary, acc) when is_binary(binary) do
    {binary, acc}
  end
  # block
  defp handle_node({:__block__, meta, block}, acc) do
    {%Node.Block{children: block,
                 line: meta[:line]}, acc}
  end
  # call
  defp handle_node({:., meta, [%Node.Var{} = var, property]}, acc) do
    {%Node.Call{module: :__PLACEHOLDER__,
                function: :apply,
                arguments: [var, property, []],
                attrs: %{native: true},
                line: meta[:line]}, acc}
  end
  defp handle_node({:., meta, [module, fun]}, acc) do
    {%Node.Call{module: module,
                function: fun,
                line: meta[:line]}, acc}
  end
  defp handle_node({%Node.Call{module: Mazurka.Runtime.Input, function: :get} = call, _, args}, acc) do
    {%{call | arguments: args, attrs: %{native: :hybrid}}, acc}
  end
  ## TODO handle apply with 0 args... for now we'll do dict since it'll probably be used more
  defp handle_node({%Node.Call{module: :__PLACEHOLDER__, function: :apply, arguments: [var, property, _]} = call, _, []}, acc) do
    {%Node.Dict{function: :fetch!,
                arguments: [var, property],
                line: call.line}, acc}
  end
  defp handle_node({%Node.Call{} = call, _, []}, acc) do
    {call, acc}
  end
  defp handle_node({%Node.Call{module: :__PLACEHOLDER__, function: :apply, arguments: [var, property, _]} = call, _, args}, acc) do
    {%{call | module: :erlang, arguments: [var, property, args]}, acc}
  end
  defp handle_node({%Node.Call{} = call, _, args}, acc) do
    {%{call | arguments: args}, acc}
  end
  # do
  defp handle_node({:do, child}, acc) do
    {{:do, child}, acc}
  end
  defp handle_node({:do, child, _}, acc) do
    {{:do, child}, acc}
  end
  defp handle_node([do: %Node.Block{} = children], acc) do
    {children, acc}
  end
  defp handle_node([do: [children]], acc) do
    {%Node.Block{children: children}, acc}
  end
  defp handle_node([do: children], acc) when is_list(children) do
    {%Node.Block{children: children}, acc}
  end
  defp handle_node([do: child], acc) do
    {child, acc}
  end
  # list
  defp handle_node(list, acc) when is_list(list) do
    {list, acc}
  end
  # map
  defp handle_node({:%{}, _, kvs}, acc) do
    {:maps.from_list(kvs), acc}
  end
  defp handle_node(%{}, acc) do
    {%{}, acc}
  end
  # map key/value
  defp handle_node({k, v}, acc) do
    {{k, v}, acc}
  end
  defp handle_node({:{}, _, values}, acc) do
    {:erlang.list_to_tuple(values), acc}
  end
  # numbers
  defp handle_node(number, acc) when is_integer(number) or is_float(number) do
    {number, acc}
  end
  # partial
  defp handle_node({:%, meta, [%Node.Call{module: module, function: function}, props]}, acc) do
    {%Node.Partial{module: module,
                   function: function,
                   props: props,
                   line: meta[:line]}, acc}
  end
  # struct
  defp handle_node({:%, meta, [module, props]}, acc) do
    {%Node.Call{module: Kernel,
                function: :struct,
                arguments: [module, props],
                attrs: %{native: true},
                line: meta[:line]}, acc}
  end
  # variable
  defp handle_node({name, meta, nil}, acc) when is_atom(name) do
    {%Node.Var{name: name,
               line: meta[:line]}, acc}
  end
  defp handle_node({name, meta, module}, acc) when is_atom(name) and is_atom(module) do
    count = if meta[:counter] do
      " ##{meta[:counter]}"
    else
      ""
    end
    name = "#{name}#{count} (#{module})" |> String.to_atom
    {%Node.Var{name: name,
               line: meta[:line]}, acc}
  end
  # case
  defp handle_node({:case, meta, [expression, %Etude.Node.Block{children: clauses}]}, acc) do
    {%Node.Case{expression: expression,
                clauses: clauses,
                line: meta[:line]}, acc}
  end
  defp handle_node({:case, meta, [expression | clauses]}, acc) do
    {%Node.Case{expression: expression,
                clauses: clauses,
                line: meta[:line]}, acc}
  end
  defp handle_node({:->, _meta, [[match], body]}, acc) do
    {{match, nil, body}, acc}
  end

  defp handle_node({:::, meta, parts}, acc) do
    parts = for part <- parts do
      case part do
        %{module: String.Chars,
          function: :to_string,
          attrs: attrs} ->
          %{part | attrs: Map.put(attrs, :native, true)}
        other ->
          other
      end
    end
    {{:::, meta, parts}, acc}
  end
  defp handle_node({:<<>>, _meta, _parts}, _acc) do
    throw "String concatentation not implemented yet"
  end

  defp handle_node({:try, meta, [expression, %Node.Var{name: handler}]}, acc) when is_atom(handler) do
    p = %Node.Partial{
      module: acc.module,
      function: handler,
      props: %{
        error: %Node.Var{name: :error, line: meta[:line]}
      },
      line: meta[:line]
    }

    t = %Node.Try{
      expression: expression,
      clauses: [
        {:error, %Node.Assign{name: :error, line: meta[:line]}, nil, p}
      ]
    }

    {t, acc}
  end
  defp handle_node({:try, meta, [expression, cases]}, acc) when is_list(cases) do
    t = %Node.Try{
      expression: expression,
      clauses: for {pattern, %Node.Var{name: handler}} <- cases do
        p = %Node.Partial{
          module: acc.module,
          function: handler,
          props: %{
            error: pattern
          },
          line: meta[:line]
        }
        {:error, %Node.Assign{name: :error, line: meta[:line]}, nil, p}
      end
    }

    {t, acc}
  end

  # local call (needs to be last)
  defp handle_node({name, meta, args}, acc) when is_atom(name) and is_list(args) do
    IO.inspect {name, meta, args}
    {%Node.Call{module: acc.module,
                function: name,
                arguments: args,
                line: meta[:line]}, acc}
  end

  defp handle_node(%{__struct__: _} = struct, acc) do
    {struct, acc}
  end
end

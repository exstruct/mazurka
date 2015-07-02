defmodule Mazurka.Compiler.Etude do
  alias Mazurka.Compiler.Utils
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
  defp handle_node({:==, meta, [lhs, rhs]}, acc) do
    {%Node.Call{module: Kernel,
                function: :==,
                arguments: [lhs, rhs],
                attrs: %{native: true},
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
  defp handle_node({:_, meta, _}, acc) do
    {%Node.Var{name: :_,
               line: meta[:line]}, acc}
  end
  # TODO add support in etude
  # defp handle_node({:->, meta, [[lhs], rhs]}, acc) do
  #   {{Clause, lhs, rhs}, acc}
  # end
  # defp handle_node({:case, meta, [expression, body]}, acc) do
  #   {{Case, expression, body}, acc}
  # end
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
    {arm1, acc} = handle_node(arm1, acc)
    {arm2, acc} = handle_node(arm2, acc)
    {%Node.Cond{expression: expression,
                arms: [arm1, arm2],
                line: meta[:line]}, acc}
  end
  defp handle_node({:&&, meta, [expression, arm1]}, acc) do
    {%Node.Cond{expression: expression,
                arms: [arm1, nil],
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
  defp handle_node({:__block__, meta, [block]}, acc) do
    {%Node.Block{children: block,
                 line: meta[:line]}, acc}
  end
  defp handle_node({:__block__, meta, block}, acc) do
    {%Node.Block{children: block,
                 line: meta[:line]}, acc}
  end
  # call
  defp handle_node({:., meta, [module, fun]}, acc) do
    {%Node.Call{module: module,
                function: fun,
                line: meta[:line]}, acc}
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
  # map key
  defp handle_node({:&&&, meta, [lhs, rhs]}, acc) do
    {%Node.Cond{expression: lhs,
                arms: [rhs],
                line: meta[:line]}, acc}
  end
  # map key/value
  defp handle_node({k, v}, acc) do
    {{k, v}, acc}
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
    {%Node.Call{module: Mazurka.Runtime,
                function: :struct,
                arguments: [module, props],
                attrs: %{native: :hybrid},
                line: meta[:line]}, acc}
  end
  # variable
  defp handle_node({name, meta, nil}, acc) when is_atom(name) do
    {%Node.Var{name: name,
               line: meta[:line]}, acc}
  end
  defp handle_node({name, meta, module}, acc) when is_atom(name) and is_atom(module) do
    name = "#{name} (#{module})" |> String.to_atom
    {%Node.Var{name: name,
               line: meta[:line]}, acc}
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
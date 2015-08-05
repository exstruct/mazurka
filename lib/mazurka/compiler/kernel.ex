defmodule Mazurka.Compiler.Kernel do
  def wrap(block) do
    input = {:__aliases__, [alias: false], [:Mazurka, :Runtime, :Input]}
    {:__block__, [],
     [{:import, [],
       [{:__aliases__, [alias: false], [:Kernel]}, [only: [..: 2,
                                                           <>: 2,
                                                           alias!: 1,
                                                           binding: 0,
                                                           binding: 1,
                                                           destructure: 2,
                                                           def: 1,
                                                           def: 2,
                                                           defdelegate: 2,
                                                           defp: 1,
                                                           defp: 2,
                                                           defmacro: 1,
                                                           defmacro: 2,
                                                           defmacrop: 1,
                                                           defmacrop: 2,
                                                           defstruct: 1,
                                                           defexception: 1,
                                                           defprotocol: 2,
                                                           defimpl: 2,
                                                           defimpl: 3,
                                                           defoverridable: 1,
                                                           in: 2,
                                                           is_nil: 1,
                                                           match?: 2,
                                                           sigil_S: 2,
                                                           sigil_s: 2,
                                                           sigil_C: 2,
                                                           sigil_R: 2,
                                                           sigil_w: 2,
                                                           var!: 2,
                                                           unless: 2,
                                                           use: 1,
                                                           use: 2,], warn: false]]},
      {:import, [],
       [{:__aliases__, [alias: false], [:Mazurka, :Compiler, :Kernel]}, [warn: false]]},
      {:alias, [], [input, [warn: false]]},
      block]}
  end

  defmacro prop(name) when Kernel.is_atom(name) do
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

  defmacro lhs or rhs do
    {:etude_cond, [], [lhs, [do: lhs, else: rhs]]}
  end

  defmacro lhs && rhs do
    {:etude_cond, [], [lhs, [do: rhs, else: false]]}
  end

  defmacro lhs and rhs do
    {:etude_cond, [], [lhs, [do: rhs, else: false]]}
  end

  defmacro lhs &&& rhs do
    {:etude_cond, [], [lhs, [do: rhs, else: :undefined]]}
  end

  defmacro elem(tuple, index) when Kernel.is_integer(index) do
    index = Kernel.+(index, 1)
    quote do
      ^:erlang.element(unquote(index), unquote(tuple))
    end
  end
  defmacro elem(tuple, index) do
    quote do
      ^:erlang.element(unquote(index) + 1, unquote(tuple))
    end
  end

  defmacro put_elem(tuple, index, value) when Kernel.is_integer(index) do
    index = Kernel.+(index, 1)
    quote do
      ^:erlang.setelement(unquote(index), unquote(tuple), unquote(value))
    end
  end
  defmacro put_elem(tuple, index, value) do
    quote do
      ^:erlang.setelement(unquote(index) + 1, unquote(tuple), unquote(value))
    end
  end

  defmacro !({:!, _, [arg]}) do
    {:etude_cond, [], [arg, [do: true, else: false]]}
  end
  defmacro !(arg) do
    {:etude_cond, [], [arg, [do: false, else: true]]}
  end

  defmacro left =~ _right when Kernel.is_binary(left) do
    true
  end
  defmacro left =~ right when Kernel.is_binary(right) do
    quote do
      ^:binary.match(unquote(left), unquote(right)) != :nomatch
    end
  end
  defmacro left =~ right do
    quote do
      ^Kernel.=~(unquote(left), unquote(right))
    end
  end

  defmacro inspect(arg, opts \\ []) do
    quote do
      ^Kernel.inspect(unquote(arg), unquote(opts))
    end
  end

  defmacro struct(struct, kv \\ []) do
    quote do
      ^Kernel.struct(unquote(struct), unquote(kv))
    end
  end

  defmacro get_in(data, keys) do
    quote do
      ^Kernel.get_in(unquote(data), unquote(keys))
    end
  end

  defmacro put_in(path, value) do
    quote do
      ^Kernel.put_in(unquote(path), unquote(value))
    end
  end

  defmacro put_in(data, keys, value) do
    quote do
      ^Kernel.put_in(unquote(data), unquote(keys), unquote(value))
    end
  end

  defmacro update_in(path, fun) do
    quote do
      ^Kernel.update_in(unquote(path), unquote(fun))
    end
  end

  defmacro update_in(data, keys, fun) do
    quote do
      ^Kernel.update_in(unquote(data), unquote(keys), unquote(fun))
    end
  end

  defmacro get_and_update_in(path, fun) do
    quote do
      ^Kernel.get_and_update_in(unquote(path), unquote(fun))
    end
  end

  defmacro get_and_update_in(data, keys, fun) do
    quote do
      ^Kernel.get_and_update_in(unquote(data), unquote(keys), unquote(fun))
    end
  end

  defmacro to_string(arg) do
    quote do
      ^String.Chars.to_string(unquote(arg))
    end
  end

  defmacro to_char_list(arg) do
    quote do
      ^List.Chars.to_char_list(unquote(arg))
    end
  end

  defmacro is_nil(arg) do
    quote do
      unquote(arg) == nil
    end
  end

  defmacro sigil_c({:<<>>, _line, [string]}, []) when Kernel.is_binary(string) do
    String.to_char_list(Macro.unescape_string(string))
  end

  defmacro sigil_c({:<<>>, line, pieces}, []) do
    binary = {:<<>>, line, Macro.unescape_tokens(pieces)}
    quote do: ^String.to_char_list(unquote(binary))
  end

  defmacro sigil_r({:<<>>, _line, [string]}, options) when Kernel.is_binary(string) do
    binary = Macro.unescape_string(string, fn(x) -> Regex.unescape_map(x) end)
    regex  = Regex.compile!(binary, :binary.list_to_bin(options))
    Macro.escape(regex)
  end

  defmacro sigil_r({:<<>>, line, pieces}, options) do
    binary = {:<<>>, line, Macro.unescape_tokens(pieces, fn(x) -> Regex.unescape_map(x) end)}
    quote do: ^Regex.compile!(unquote(binary), unquote(:binary.list_to_bin(options)))
  end

  e_macros = [abs: [:number],
              apply: [:fun, :args],
              apply: [:module, :fun, :args],
              binary_part: [:binary, :start, :length],
              bit_size: [:bitstring],
              byte_size: [:binary],
              div: [:left, :right],
              function_exported?: [:module, :function, :arity],
              hd: [:list],
              is_atom: [:term],
              is_binary: [:term],
              is_bitstring: [:term],
              is_boolean: [:term],
              is_float: [:term],
              is_function: [:term],
              is_integer: [:term],
              is_list: [:term],
              is_map: [:term],
              is_number: [:term],
              is_pid: [:term],
              is_port: [:term],
              is_reference: [:term],
              is_tuple: [:term],
              length: [:list],
              make_ref: [],
              map_size: [:map],
              max: [:first, :second],
              min: [:first, :second],
              node: [],
              node: [:arg],
              rem: [:left, :right],
              round: [:number],
              send: [:dest, :msg],
              self: [],
              spawn: [:fun],
              spawn: [:module, :fun, :args],
              spawn_link: [:fun],
              spawn_link: [:module, :fun, :args],
              spawn_monitor: [:fun],
              spawn_monitor: [:module, :fun, :args],
              throw: [:term],
              tl: [:list],
              trunc: [:number],
              tuple_size: [:tuple],
              not: [:arg]
            ]

  for {name, args} <- e_macros do
    args = Enum.map(args, &(Macro.var(&1, nil)))

    defmacro unquote(name)(unquote_splicing(args)) do
      {:^, [], [{{:., [], [:erlang, unquote(name)]}, [], unquote(args)}]}
    end
  end

  e_infix_macros = [:+,
                    :-,
                    :*,
                    :/,
                    :++,
                    :--,
                    :<,
                    :>,
                    :<=,
                    :>=,
                    :==,
                    :!=,
                    :===,
                    :!==
                    ]
  for name <- e_infix_macros do
    defmacro unquote(name)(left, right) do
      {:^, [], [{{:., [], [:erlang, unquote(name)]}, [], [left, right]}]}
    end
  end
end

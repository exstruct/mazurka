defmodule Mazurka.Compiler.Utils do
  def eval(quoted, env) do
    {out, []} = quoted
    |> Macro.expand(env)
    |> Code.eval_quoted([], env)
    out
  end

  def expand(quoted, env) do
    Macro.postwalk(quoted, fn
      ({type, meta, children}) ->
        meta = replace_kernel(meta)
        Macro.expand({type, meta, children}, env)
      ([{:do, _} | _] = doblock) ->
        Enum.map(doblock, fn({key, children}) ->
          children = expand(children, env)
          {key, children}
        end)
      ({name, children}) when is_atom(name) ->
        children = expand(children, env)
        {name, children}
      (other) ->
        Macro.expand(other, env)
    end)
  end

  defp replace_kernel(meta) do
    if meta[:import] == Kernel do
      Keyword.put(meta, :import, Mazurka.Compiler.Kernel)
    else
      meta
    end
  end

  def register(name, block) do
    register(name, block, nil)
  end
  def register(name, block, meta) do
    register(nil, name, block, meta)
  end
  def register(mediatype, name, block, meta) do
    {{:., [],
        [{:__aliases__, [alias: false], [:Mazurka, :Compiler, :Utils]}, :save]}, [],
       [mediatype, name, block, meta]}
    |> Mazurka.Compiler.Kernel.wrap
  end

  defmacro save(mediatype, name, block, meta) do
    mediatype = eval(mediatype, __CALLER__)
    put(__CALLER__, mediatype, name, block, meta)
  end

  def put(caller, mediatype, name, value, meta \\ nil) do
    module = caller.module
    Module.register_attribute(module, __MODULE__, accumulate: true)
    Module.put_attribute(module, __MODULE__, {mediatype, name, value, meta})
    nil
  end

  def get(caller) do
    caller.module
    |> Module.get_attribute(__MODULE__)
  end
  def get(caller, name) do
    get(caller)
    |> Enum.filter(fn({_, item, _, _}) ->
      item == name
    end)
  end
end
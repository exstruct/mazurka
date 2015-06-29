defmodule Mazurka.Compiler do
  alias Mazurka.Compiler.Utils

  @doc """
  Compile a resource with the environment attributes
  """
  defmacro compile(env) do
    mediatypes = compile_mediatypes(env)
    body(mediatypes)
  end

  @doc false
  defp body(mediatypes) do
    quote do
      @doc """
      Handle a given request
      """
      def handle(request, resolve) do
        exec("*", "*", %{}, request, resolve)
      end

      @doc """
      Handle a given request, passing a list of acceptable mediatypes
      """
      def handle(request, resolve, []) do
        {:error, :unacceptable}
      end
      def handle(request, resolve, [{_, {type, subtype, params}} | accepts]) do
        case exec(type, subtype, params, request, resolve) do
          {:error, :unacceptable} ->
            handle(request, resolve, accepts)
          res ->
            res
        end
      end
      def handle(request, resolve, [{type, subtype, params} | accepts]) do
        case exec(type, subtype, params, request, resolve) do
          {:error, :unacceptable} ->
            handle(request, resolve, accepts)
          res ->
            res
        end
      end

      @doc false
      defp exec(type, subtype, params, request, resolve)
      unquote_splicing(mediatypes)
      defp exec(_, _, _, _, _) do
        {:error, :unacceptable}
      end
    end
  end

  defp compile_mediatypes(env) do
    globals = compile_globals(env)
    Module.get_attribute(env.module, :mz_mediatype)
    |> Utils.eval(env)
    |> Enum.map(&(Mazurka.Compiler.Mediatype.compile(&1, globals, env)))
    []
  end

  defp compile_globals(env) do
    %{
      conditions: Mazurka.Resource.Condition.attribute,
      events: Mazurka.Resource.Event.attribute,
      lets: Mazurka.Resource.Let.attribute,
      params: Mazurka.Resource.Param.attribute,
    }
    |> Enum.reduce(%{}, fn({key, name}, acc) ->
      values = Module.get_attribute(env.module, name) || []
      Dict.put(acc, key, values)
    end)
  end
end

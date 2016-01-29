defmodule Mazurka.Resource.Link.Assertions do
  require Logger
  import Mazurka.Resource.Link.Utils

  case Mazurka.Utils.env do
    :dev ->
      defmacro link_to(module, props, conn) do
        quote bind_quoted: binding do
          import Mazurka.Resource.Link.Assertions
          {module, props, conn}
          |> assert_exists()
          |> assert_resolve()
          |> return_value()
        end
      end
    :prod ->
      defmacro link_to(module, props, conn) do
        quote bind_quoted: binding do
          import Mazurka.Resource.Link.Assertions
          {module, props, conn}
          |> assert_resolve()
          |> return_value()
        end
      end
    _ ->
      defmacro link_to(module, props, conn) do
        quote bind_quoted: binding do
          import Mazurka.Resource.Link.Assertions
          {module, props, conn}
          |> assert_exists()
          |> assert_resolve()
          |> return_value!(module)
        end
      end
  end

  def assert_exists({resource, _, conn} = res) do
    module = resource_to_module(resource)
    Code.ensure_loaded?(module)
    if function_exported?(module, :affordance_partial, 5) do
      res
    else
      router = conn.private.mazurka_router
      Logger.error """
      Trying to link to non-existant resource #{inspect(resource)} from #{inspect(conn.private.mazurka_resource)}

      This error can be fixed by creating the appropriate module:

          defmodule #{inspect(module)} do
            use Mazurka.Resource

            ...
          end

      and adding it to #{inspect(router)}:

          defmodule #{inspect(router)} do
            get "/path/to/resource", #{inspect(resource)}
          end
      """
      false
    end
  end
  def assert_exists(res) do
    res
  end

  def assert_resolve({resource, props, conn}) do
    router = conn.private.mazurka_router
    params = props.params
    case router.resolve(resource, params) do
      {:ok, _method, _path, resource_params} ->
        {resource, Map.put(props, :resource_params, resource_params), conn}
      _ ->
        case router.params(resource) do
          {:ok, expected} ->
            Logger.warn """
            Trying to link to resource #{inspect(resource)} from #{inspect(conn.private.mazurka_resource)}

            The resource did not receive the required parameters to continue:

                expected_keys: #{inspect(expected)}
                actual_params: #{inspect(params)}

            Assure the required parameters are passed
            """
          _ ->
            Logger.warn """
            Trying to link to resource #{inspect(resource)} from #{inspect(conn.private.mazurka_resource)}

            The resource has not been added to the router. This can be accomplished with something like:

                defmodule #{inspect(router)} do
                  get "/path/to/resource", #{inspect(resource)}
                end
            """
        end
        false
    end
  end
  def assert_resolve(res) do
    res
  end

  def return_value({module, props, _}) do
    {:partial, {resource_to_module(module), :affordance_partial, props}}
  end
  def return_value(_) do
    {:ok, :undefined}
  end

  def return_value!(res, module) do
    case return_value(res) do
      {:ok, :undefined} ->
        {:error, {:invalid_link_to}, module}
      other ->
        other
    end
  end
end

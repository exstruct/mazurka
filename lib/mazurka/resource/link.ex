defmodule Mazurka.Resource.Link do
  @moduledoc false

  use Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :mazurka_links, accumulate: true)
      import unquote(__MODULE__)
      alias unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Link to another resource
  """

  defmacro link_to(resource, params \\ nil, input \\ nil, opts \\ []) do
    params = format_params(params)
    input = format_params(input)
    Module.put_attribute(__CALLER__.module, :mazurka_links, resource)

    quote do
      conn = unquote(Utils.conn)
      router = unquote(Utils.router)

      resource = case unquote(resource) do
                   resource when not is_nil(router) ->
                     source = %{resource: __MODULE__,
                                file: __ENV__.file,
                                line: __ENV__.line,
                                params: unquote(Utils.params),
                                input: unquote(Utils.input),
                                mediatype: unquote(Utils.mediatype),
                                opts: unquote(Utils.opts)}
                     Mazurka.Router.resolve_resource(router, resource, source, conn)
                   resource ->
                     resource
                 end

      resource.affordance(
        unquote(Utils.mediatype),
        unquote(params),
        unquote(input),
        conn,
        router,
        unquote(opts)
      )
    end
  end

  @doc """
  Transition to another resource
  """

  defmacro transition_to(resource, params \\ nil, input \\ nil, opts \\ []) do
    params = format_params(params)
    input = format_params(input)

    quote do
      conn = unquote(Utils.conn)

      target = Mazurka.Resource.Link.resolve(
        unquote(resource),
        unquote(params),
        unquote(input),
        conn,
        unquote(Utils.router),
        unquote(opts)
      )

      unquote(Utils.conn) = Mazurka.Conn.transition(conn, target)

      target
    end
  end

  @doc """
  Invalidate another resource
  """

  defmacro invalidates(resource, params \\ nil, input \\ nil, opts \\ []) do
    params = format_params(params)
    input = format_params(input)

    quote do
      conn = unquote(Utils.conn)

      target = Mazurka.Resource.Link.resolve(
        unquote(resource),
        unquote(params),
        unquote(input),
        conn,
        unquote(Utils.router),
        unquote(opts)
      )

      unquote(Utils.conn) = Mazurka.Conn.invalidate(conn, target)

      target
    end
  end

  defp format_params(nil) do
    {:%{}, [], []}
  end
  defp format_params({:%{}, meta, items}) do
    {:%{}, meta, Enum.map(items, fn({name, value}) ->
      {to_string(name), value}
    end)}
  end
  defp format_params(items) when is_list(items) do
    {:%{}, [], Enum.map(items, fn({name, value}) ->
      {to_string(name), value}
    end)}
  end
  defp format_params(other) do
    quote do
      Enum.reduce(unquote(other), %{}, fn({name, value}, acc) ->
        Map.put(acc, to_string(name), value)
      end)
    end
  end

  defmacro resolve(resource, params, input, conn, router, opts) do
    current_params = Utils.params
    current_input = Utils.input
    current_mediatype = Utils.mediatype
    current_opts = Utils.opts

    quote bind_quoted: binding do
      case router do
        nil ->
          raise Mazurka.MissingRouterException, resource: resource, params: params, input: input, conn: conn, opts: opts
        router ->
          affordance = %Mazurka.Affordance{resource: resource,
                                           params: params,
                                           input: input,
                                           opts: opts}

          source = %{resource: __MODULE__,
                     file: __ENV__.file,
                     line: __ENV__.line,
                     params: current_params,
                     input: current_input,
                     mediatype: current_mediatype,
                     opts: current_opts}

          Mazurka.Router.resolve(router, affordance, source, conn)
      end
    end
  end

  defmacro rel_self do
    quote do
      unquote(__MODULE__).resolve(
        __MODULE__,
        unquote(Utils.params),
        unquote(Utils.input),
        unquote(Utils.conn),
        unquote(Utils.router),
        unquote(Utils.opts)
      )
    end
  end

  defmacro __before_compile__(_) do
    quote unquote: false do
      links = @mazurka_links |> Enum.uniq() |> Enum.sort()
      def links do
        unquote(links)
      end
    end
  end
end

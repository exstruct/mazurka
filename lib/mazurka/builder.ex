defmodule Mazurka.Builder do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :mazurka_mediatypes, accumulate: true)

      unquote(builder())
      @before_compile unquote(__MODULE__)
    end
  end

  if Code.ensure_compiled?(Plug.Builder) do
    defp builder do
      quote do
        use Plug.Builder
      end
    end
  else
    defp builder do
      quote do
        def init(opts) do
          opts
        end

        def call(conn, _opts) do
          conn
        end

        defoverridable init: 1, call: 2
      end
    end
  end

  defmacro put(subject, key, value) do
    quote do
      key = unquote(key)

      case unquote(subject) do
        %{^key => value} when not is_nil(value) ->
          # TODO improve the error
          throw(:already_set)

        subject ->
          Map.put(subject, key, unquote(value))
      end
    end
  end

  defmacro append(subject, key, value) do
    quote do
      %{unquote(key) => list} = subject = unquote(subject)
      %{subject | unquote(key) => [unquote(value) | list]}
    end
  end

  def get_doc(module) do
    case Module.get_attribute(module, :doc) do
      {_line, doc} ->
        Module.delete_attribute(module, :doc)
        doc

      _ ->
        nil
    end
  end

  defmacro __before_compile__(%{module: module}) do
    subject = Module.get_attribute(module, :mazurka_subject)

    mediatypes =
      module
      |> Module.get_attribute(:mazurka_mediatypes)
      |> :lists.reverse()
      |> Stream.uniq()
      |> Stream.flat_map(fn impl ->
        impl
        |> Mazurka.Mediatype.provides()
        |> Stream.map(&{&1, impl})
      end)
      |> Stream.uniq_by(&elem(&1, 0))
      |> Enum.to_list()

    %{value: %{line: line}} = subject
    opts = Macro.var(:opts, __MODULE__)

    vars = %{
      conn: Macro.var(:conn, __MODULE__),
      opts: Macro.var(:opts, __MODULE__)
    }

    impls =
      mediatypes
      |> Stream.map(&elem(&1, 1))
      |> Enum.uniq_by(&Mazurka.Mediatype.key/1)

    # TODO warn if there are no mediatypes

    quote line: line do
      defoverridable call: 2

      def call(conn, unquote(opts)) do
        conn = super(conn, unquote(opts))
        {accepts, conn} = Mazurka.Conn.accepts(conn)

        {buffer, conn} =
          case negotiate_content_type(accepts, accepts, conn),
            do:
              unquote([
                {:->, [line: line],
                 [
                   [false],
                   quote do
                     raise Mazurka.UnacceptableContentTypeException,
                       acceptable:
                         unquote(
                           for {mediatype, _impl} <- mediatypes do
                             Macro.escape(mediatype)
                           end
                         ),
                       content_type: accepts,
                       conn: conn
                   end
                 ]}
                | Enum.map(impls, &compile_action_impl(&1, subject, vars))
              ])

        Mazurka.Conn.send_resp(conn, buffer)
      end

      def affordance(conn, opts) do
        mediatype = Mazurka.Conn.get_content_type(conn)

        case negotiate_content_type([mediatype], false, conn),
          do:
            unquote([
              {:->, [line: line],
               [
                 [false],
                 quote do
                   {false, conn}
                 end
               ]}
              | Enum.map(impls, &compile_affordance_impl(&1, subject, vars))
            ])
      end

      unquote_splicing(
        for {match, mediatype, impl} <- expand_wildcards(mediatypes) do
          selector = compile_mediatype(match)
          key = Mazurka.Mediatype.key(impl)

          quote line: line do
            defp negotiate_content_type([unquote(selector) | _], _, conn) do
              {unquote(key), unquote(Macro.escape(mediatype)), conn}
            end
          end
        end
      )

      defp negotiate_content_type([_ | mediatypes], accepts, conn) do
        negotiate_content_type(mediatypes, accepts, conn)
      end

      defp negotiate_content_type([], [], conn) do
        accepts = [{"*", "*", %{}}]
        negotiate_content_type(accepts, accepts, conn)
      end

      defp negotiate_content_type([], _, _conn) do
        false
      end
    end
  end

  defp compile_action_impl(impl, subject, %{conn: conn} = vars) do
    key = Mazurka.Mediatype.key(impl)
    action = Mazurka.Mediatype.action(impl, subject, vars)
    match = quote(do: {unquote(key), content_type, conn})

    {:->, [],
     [
       [match],
       quote do
         unquote(conn) = Mazurka.Conn.put_content_type(conn, content_type)
         unquote(action)
       end
     ]}
  end

  defp compile_affordance_impl(impl, subject, %{conn: conn} = vars) do
    key = Mazurka.Mediatype.key(impl)
    affordance = Mazurka.Mediatype.affordance(impl, subject, vars)
    match = quote(do: {unquote(key), _, unquote(conn)})
    {:->, [], [[match], affordance]}
  end

  defp compile_mediatype({category, type, params}) do
    params =
      Enum.map(params, fn {key, value} ->
        {to_string(key), Macro.escape(value)}
      end)

    quote do
      {
        unquote(Macro.escape(category)),
        unquote(Macro.escape(type)),
        %{unquote_splicing(params)}
      }
    end
  end

  defp expand_wildcards(mediatypes) do
    mediatypes
    |> Enum.flat_map_reduce(%{}, fn {{primary, secondary, _params} = orig, impl}, acc ->
      {[{orig, orig, impl}], acc}
      |> expand_wildcard({"*", "*", %{}}, orig, impl)
      |> expand_wildcard({primary, "*", %{}}, orig, impl)
      |> expand_wildcard({"*", secondary, %{}}, orig, impl)
    end)
    |> elem(0)
  end

  defp expand_wildcard({acc, used}, key, orig, impl) do
    if Map.has_key?(used, key) do
      {acc, used}
    else
      {Stream.concat(acc, [{key, orig, impl}]), Map.put(used, key, true)}
    end
  end
end

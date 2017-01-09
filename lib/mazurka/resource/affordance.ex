defmodule Mazurka.Resource.Affordance do
  @moduledoc false

  alias Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      @doc """
      Create an affordance block

          mediatype #{inspect(__MODULE__)} do
            affordance do
              # affordance goes here
            end
          end
      """

      defmacro affordance(block) do
        mediatype = __MODULE__
        quote do
          require Mazurka.Resource.Affordance
          Mazurka.Resource.Affordance.affordance(unquote(mediatype), unquote(block))
        end
      end
    end
  end

  @doc """
  Create an affordance block for a mediatype

      affordance Mazurka.Mediatype.MyCustomMediatype do
        # affordance goes here
      end
  """

  defmacro affordance(mediatype, [do: block]) do
    quote location: :keep do
      defp mazurka__match_affordance(unquote(mediatype) = unquote(Utils.mediatype), unquote_splicing(Utils.arguments), unquote(Utils.scope)) do
        Mazurka.Resource.Utils.Scope.dump()
        var!(conn) = unquote(Utils.conn())
        affordance = rel_self()
        props = unquote(block)
        unquote(Utils.conn()) = var!(conn)
        unquote(mediatype).handle_affordance(affordance, props)
      end
    end
  end

  defmacro __before_compile__(_) do
    quote location: :keep do
      def affordance(content_type = {_, _, _}, unquote_splicing(Utils.arguments)) do
        case mazurka__provide_content_type(content_type) do
          nil ->
            %Mazurka.Affordance.Unacceptable{resource: __MODULE__,
                                             params: unquote(Utils.params),
                                             input: unquote(Utils.input),
                                             opts: unquote(Utils.opts)}
          mediatype ->
            affordance(mediatype, unquote_splicing(Utils.arguments))
        end
      end
      def affordance(mediatype, unquote_splicing(Utils.arguments)) when is_atom(mediatype) do
        case __mazurka_check_params__(unquote(Utils.params)) do
          {[], []} ->
            scope = __mazurka_scope__(mediatype, unquote_splicing(Utils.arguments))
            case __mazurka_conditions__(unquote_splicing(Utils.arguments), scope) do
              {:error, _} ->
                %Mazurka.Affordance.Undefined{resource: __MODULE__,
                                              mediatype: mediatype,
                                              params: unquote(Utils.params),
                                              input: unquote(Utils.input),
                                              opts: unquote(Utils.opts)}
              :ok ->
                mazurka__match_affordance(mediatype, unquote_splicing(Utils.arguments), scope)
            end
          {missing, _} when length(missing) > 0 ->
            raise Mazurka.MissingParametersException, params: missing, conn: unquote(Utils.conn())
          _ ->
            %Mazurka.Affordance.Undefined{resource: __MODULE__,
                                          mediatype: mediatype,
                                          params: unquote(Utils.params),
                                          input: unquote(Utils.input),
                                          opts: unquote(Utils.opts)}
        end
      end

      defp mazurka__match_affordance(mediatype, unquote_splicing(Utils.arguments), scope) do
        mazurka__default_affordance(mediatype, unquote_splicing(Utils.arguments), scope)
      end
    end
  end
end

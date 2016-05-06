defmodule Mazurka.Resource.Action do
  @moduledoc false

  use Mazurka.Resource.Utils

  defmacro __using__(_) do
    quote do
      @doc """
      Create an action block

          mediatype #{inspect(__MODULE__)} do
            action do
              # action goes here
            end
          end
      """

      defmacro action(block) do
        mediatype = __MODULE__
        quote do
          require Mazurka.Resource.Action
          Mazurka.Resource.Action.action(unquote(mediatype), unquote(block))
        end
      end
    end
  end

  @doc """
  Create an action block for a mediatype

      action Mazurka.Mediatype.MyCustomMediatype do
        # action goes here
      end
  """

  defmacro action(mediatype, [do: block]) do
    quote do
      defp mazurka__match_action(unquote(mediatype) = unquote(Utils.mediatype), unquote_splicing(arguments), unquote(scope)) do
        action = unquote(block)
        res = unquote(mediatype).__handle_action__(action)
        event(res, unquote_splicing(arguments))
      end
    end
  end

  defmacro __before_compile__(_) do
    quote location: :keep do
      def action(content_type = {_, _, _}, unquote_splicing(arguments)) do
        case mazurka__provide_content_type(content_type) do
          nil ->
            raise Mazurka.UnacceptableContentTypeException, [
              content_type: content_type,
              acceptable: mazurka__acceptable_content_types(),
              conn: unquote(conn)
            ]
          mediatype ->
            case mazurka__check_params(unquote(params)) do
              {[], []} ->
                scope = mazurka__scope(mediatype, unquote_splicing(arguments))
                case mazurka__conditions(unquote_splicing(arguments), scope) do
                  {:error, message} ->
                    raise Mazurka.ConditionException, message: message, conn: unquote(conn)
                  :ok ->
                    case mazurka__validations(unquote_splicing(arguments), scope) do
                      {:error, message} ->
                        raise Mazurka.ValidationException, message: message, conn: unquote(conn)
                      :ok ->
                        mazurka__match_action(mediatype, unquote_splicing(arguments), scope)
                    end
                end
              {missing, nil_params} ->
                raise Mazurka.MissingParametersException, params: missing ++ nil_params, conn: unquote(conn)
            end
        end
      end

      defp mazurka__match_action(_, unquote_splicing(arguments), _) do
        ## TODO raise exception
      end
    end
  end
end

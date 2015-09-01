defmodule Mazurka.Mediatype do
  use Behaviour

  @type ast :: Macro.t
  @type props :: Map.t
  defmacrocallback handle_action(ast) :: any
  defmacrocallback handle_affordance(ast, props) :: any
  defmacrocallback handle_error(ast) :: any

  @doc """
  Create a mediatype with default macros for action, affordance, error, and partial

      defmodule Mazurka.Mediatype.MyMediatype do
        use Mazurka.Mediatype
      end
  """
  defmacro __using__(_) do
    quote [bind_quoted: []] do
      @behaviour Mazurka.Mediatype

      defmacro action(block) do
        mediatype = __MODULE__
        quote do
          require Mazurka.Resource.Action
          Mazurka.Resource.Action.action(unquote(mediatype), unquote(block))
        end
      end

      defmacro affordance(block) do
        mediatype = __MODULE__
        quote do
          require Mazurka.Resource.Affordance
          Mazurka.Resource.Affordance.affordance(unquote(mediatype), unquote(block))
        end
      end

      defmacro error(name, block) do
        mediatype = __MODULE__
        quote do
          require Mazurka.Resource.Error
          Mazurka.Resource.Error.error(unquote(mediatype), unquote(name), unquote(block))
        end
      end

      defmacro partial(name, block) do
        mediatype = __MODULE__
        quote do
          require Mazurka.Resource.Partial
          Mazurka.Resource.Partial.partial(unquote(mediatype), unquote(name), unquote(block))
        end
      end

      defmacro provides(type) do
        mediatype = __MODULE__
        quote do
          require Mazurka.Resource.Provides
          Mazurka.Resource.Provides.provides(unquote(mediatype), unquote(type))
        end
      end
    end
  end
end

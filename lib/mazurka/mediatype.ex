defmodule Mazurka.Mediatype do
  @doc """
  Create a mediatype with default macros for action, affordance, error, and partial

      defmodule Mazurka.Mediatype.MyMediatype do
        use Mazurka.Mediatype
      end
  """
  defmacro __using__(_) do
    quote [bind_quoted: []] do
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
    end
  end
end
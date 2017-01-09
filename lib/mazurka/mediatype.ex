defmodule Mazurka.Mediatype do
  @moduledoc """
  TODO write the docs
  """

  @type ast :: Macro.t
  @type props :: Map.t

  @doc """
  TODO write the docs
  """
  @macrocallback handle_action(ast) :: any

  @doc """
  TODO write the docs
  """
  @macrocallback handle_affordance(ast, props) :: any

  @doc """
  TODO write the docs
  """
  @callback content_types() :: [{binary, binary, binary, module}]

  @doc """
  Create a mediatype with default macros for action, affordance, error, and provides

      defmodule Mazurka.Mediatype.MyMediatype do
        use Mazurka.Mediatype
      end
  """
  defmacro __using__(_) do
    quote unquote: false, location: :keep do
      @behaviour Mazurka.Mediatype
      alias Mazurka.Resource.Utils

      defmacro __using__(_) do
        content_types = content_types() |> Macro.escape()
        quote location: :keep do
          require Mazurka.Resource.Provides
          Mazurka.Resource.Provides.__mediatype_provides__(unquote(__MODULE__), unquote(content_types))
          import unquote(__MODULE__), except: [handle_action: 1, handle_affordance: 2, content_types: 0]

          defp mazurka__default_affordance(unquote(__MODULE__) = unquote(Utils.mediatype), unquote_splicing(Utils.arguments), unquote(Utils.scope)) do
            affordance = Mazurka.Resource.Link.resolve(__MODULE__, unquote_splicing(Utils.arguments))
            unquote(__MODULE__).handle_affordance(affordance, nil)
          end
        end
      end

      use Mazurka.Resource.Action
      use Mazurka.Resource.Affordance
      use Mazurka.Resource.Provides
    end
  end
end

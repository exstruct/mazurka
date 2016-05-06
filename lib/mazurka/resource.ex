defmodule Mazurka.Resource do
  @moduledoc """
  TODO write the docs
  """

  use Mazurka.Resource.Utils

  @doc """
  Initialize a module as a mazurka resource

      defmodule My.Resource do
        use Mazurka.Resource
      end

  TODO document condition, event, input, let, link, mediatype, param, params, and validation
  """
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      use Mazurka.Resource.Condition
      use Mazurka.Resource.Event
      use Mazurka.Resource.Input
      use Mazurka.Resource.Let
      use Mazurka.Resource.Link
      use Mazurka.Resource.Mediatype
      use Mazurka.Resource.Param
      use Mazurka.Resource.Validation
      use Mazurka.Resource.Utils.Scope
    end
  end

  defmacro __before_compile__(_) do
    quote location: :keep do
      @doc """
      Execute a request against the #{inspect(__MODULE__)} resource

          accept = [
            {"application", "json", %{}},
            {"text", "*", %{}}
          ]
          params = %{"user" => "123"}
          input = %{"name" => "Joe"}
          conn = %Plug.Conn{}
          router = My.Router

          #{inspect(__MODULE__)}.action(accept, params, input, conn, router)
      """
      def action(accept, params, input, conn, router \\ nil, opts \\ [])

      def action(content_types, unquote_splicing(arguments)) when is_list(content_types) do
        case mazurka__select_content_type(content_types) do
          nil ->
            raise Mazurka.UnacceptableContentTypeException, [
              content_type: content_types,
              acceptable: mazurka__acceptable_content_types()
            ]
          content_type ->
            {response, conn} = action(content_type, unquote_splicing(arguments))
            {response, content_type, conn}
        end
      end

      @doc """
      Render an affordance for #{inspect(__MODULE__)}

          content_type = {"appliction", "json", %{}}
          params = %{"user" => "123"}
          input = %{"name" => "Fred"}
          conn = %Plug.Conn{}
          router = My.Router

          #{inspect(__MODULE__)}.affordance(content_type, params, input, conn, router)
      """
      def affordance(accept, params, input, conn, router \\ nil, opts \\ [])

      def affordance(content_types, unquote_splicing(arguments)) when is_list(content_types) do
        case mazurka__select_content_type(content_types) do
          nil ->
            raise Mazurka.UnacceptableContentTypeException, [
              content_type: content_types,
              acceptable: mazurka__acceptable_content_types()
            ]
          content_type ->
            response = affordance(content_type, unquote_splicing(arguments))
            {response, content_type}
        end
      end
    end
  end
end

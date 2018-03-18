defmodule Mazurka.UnacceptableContentTypeError do
  @moduledoc """
  This exception is thrown when no acceptable content types are found for a request
  """

  defexception [:acceptable, :content_type]

  def message(%{content_type: [content_type]} = ex) do
    message(%{ex | content_type: content_type})
  end

  def message(%{content_type: content_types}) when is_list(content_types) do
    types = content_types |> Enum.map(&format_type/1) |> Enum.join(", ")
    "Unacceptable content types #{inspect(types)}"
  end

  def message(%{content_type: content_type}) do
    "Unacceptable content type #{inspect(format_type(content_type))}"
  end

  defp format_type({type, subtype, _params}) do
    # TODO add params
    "#{type}/#{subtype}"
  end
end

defmodule Mazurka.ConditionError do
  @moduledoc """
  This exception is thrown when a condition fails
  """

  defexception [:message]

  def message(%{message: message}) do
    message || "Invalid request"
  end
end

defmodule Mazurka.AffordanceError do
  @moduledoc """
  Thrown when an affordance cannot be rendered, due to a condition failure
  """

  defexception [:conn, :error]

  def message(%{error: error}) do
    Exception.message(error)
  end
end

defmodule Mazurka.ValidationError do
  @moduledoc """
  This exception is thrown when a validation fails
  """

  defexception [:message, :input, :failure]

  def message(%{message: message, input: input, failure: failure}) do
    message || "Input #{input} #{failure || "failed to validate"}"
  end
end

defmodule Mazurka.WrappedError do
  @moduledoc """
  Wraps the connection in an error which is meant
  to be handled upper in the stack.
  """

  defexception [:conn, :kind, :reason, :stack]

  def message(%{kind: kind, reason: reason, stack: stack}) do
    Exception.format_banner(kind, reason, stack)
  end

  @doc """
  Reraises an error or a wrapped one.
  """
  def reraise(_conn, :error, %__MODULE__{stack: stack} = reason) do
    :erlang.raise(:error, reason, stack)
  end

  def reraise(conn, :error, reason) do
    stack = System.stacktrace()
    wrapper = %__MODULE__{conn: conn, kind: :error, reason: reason, stack: stack}
    :erlang.raise(:error, wrapper, stack)
  end

  def reraise(_conn, kind, reason) do
    :erlang.raise(kind, reason, System.stacktrace())
  end
end

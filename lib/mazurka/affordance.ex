defmodule Mazurka.Affordance do
  @moduledoc """
  TODO write the docs
  """

  defstruct [:resource,
             :mediatype,
             :params,
             :input,
             :opts,

             :method,

             :authority,
             :fragment,
             :host,
             :path,
             :port,
             :query,
             :scheme,
             :userinfo]

  @doc false
  def fetch(affordance, key) do
    Map.fetch(affordance, key)
  end
end

defimpl String.Chars, for: Mazurka.Affordance do
  def to_string(affordance) do
    affordance
    |> Map.take([:authority, :fragment, :host, :path, :port, :query, :scheme, :userinfo])
    |> String.Chars.URI.to_string()
  end
end

defmodule Mazurka.Affordance.Unacceptable do
  @moduledoc """
  TODO write the docs
  """

  defstruct [:resource,
             :params,
             :input,
             :opts]
end

defmodule Mazurka.Affordance.Undefined do
  @moduledoc """
  TODO write the docs
  """

  defstruct [:resource,
             :mediatype,
             :params,
             :input,
             :opts]
end

defimpl String.Chars, for: [Mazurka.Affordance.Unacceptable, Mazurka.Affordance.Undefined] do
  def to_string(_) do
    ""
  end
end

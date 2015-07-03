defmodule Mazurka.Resource do
  @doc """
  Initialize a module as a mazurka resource

      defmodule My.Resource do
        use Mazurka.Resource
      end
  """
  defmacro __using__(opts) do
    # Mazurka.Compiler.Utils.put(__CALLER__, nil, __MODULE__, opts)
    quote do
      import Mazurka.Resource.Condition
      import Mazurka.Resource.Event
      import Mazurka.Resource.Let
      import Mazurka.Resource.Mediatype
      import Mazurka.Resource.Param
      import Mazurka.Resource.Test

      require Mazurka.Compiler.Utils
      require Logger

      @before_compile {Mazurka.Compiler, :compile}
    end
  end
end
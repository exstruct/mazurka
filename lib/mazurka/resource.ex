defmodule Mazurka.Resource do
  @doc """
  Initialize a module as a mazurka resource

      defmodule My.Resource do
        use Mazurka.Resource
      end
  """
  defmacro __using__(_opts) do
    # Mazurka.Compiler.Utils.put(__CALLER__, nil, __MODULE__, opts)
    quote do
      import Mazurka.Resource.Condition
      import Mazurka.Resource.Event
      import Mazurka.Resource.Let
      import Mazurka.Resource.Mediatype
      import Mazurka.Resource.Param
      import Mazurka.Resource.Partial
      use Mazurka.Resource.Test
      import Mazurka.Resource.Validation

      require Mazurka.Compiler.Utils
      require Logger

      require Mazurka.Compiler
      @before_compile {Mazurka.Compiler, :compile}
    end
  end
end

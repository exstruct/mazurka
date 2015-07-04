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
      import Mazurka.Resource.Test
      import unquote(__MODULE__)

      require Mazurka.Compiler.Utils
      require Logger

      require Mazurka.Compiler
      @before_compile {Mazurka.Compiler, :compile}
    end
  end

  defmacro @({:doc, _, [doc]}) do
    ## TODO figure out how to get the following functions name
    name = :todo
    quote do
      Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {unquote(name), 0}, [], unquote(doc))
    end
  end
end
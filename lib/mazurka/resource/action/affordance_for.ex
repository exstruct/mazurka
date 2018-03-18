defmodule Mazurka.Resource.Action.AffordanceFor do
  defstruct module: nil,
            params: [],
            input: [],
            opts: [],
            line: 0

  alias Mazurka.Resource.Builder

  defmacro affordance_for(module, params \\ [], input \\ [], opts \\ []) do
    Builder.child(
      quote do
        %unquote(__MODULE__){
          module: unquote(module),
          params: unquote(Macro.escape(params)),
          input: unquote(Macro.escape(input)),
          opts: unquote(Macro.escape(opts)),
          line: __ENV__.line
        }
      end
    )
  end
end

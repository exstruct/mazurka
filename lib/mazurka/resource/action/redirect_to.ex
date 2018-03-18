defmodule Mazurka.Resource.Action.RedirectTo do
  defstruct conn: nil,
            module: nil,
            params: [],
            input: [],
            opts: [],
            line: 0

  alias Mazurka.Resource.Builder

  defmacro redirect_to(conn, module, params \\ [], input \\ [], opts \\ []) do
    Builder.child(
      quote do
        %unquote(__MODULE__){
          conn: unquote(Macro.escape(conn)),
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

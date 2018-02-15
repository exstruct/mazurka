defprotocol Mazurka.Serializer.JSON do
  @moduledoc false
  @fallback_to_any true

  Kernel.defmacro __using__(_) do
    quote do
      @doc false
      def enter(value, vars) do
        Mazurka.Serializer.JSON.enter(value, vars, __MODULE__)
      end

      @doc false
      def exit(value, vars) do
        Mazurka.Serializer.JSON.exit(value, vars, __MODULE__)
      end
    end
  end

  def enter(value, vars, impl)
  def exit(value, vars, impl)
end

defimpl Mazurka.Serializer.JSON, for: Any do
  def enter(_, vars, _) do
    {nil, vars}
  end

  def exit(_, vars, _) do
    {nil, vars}
  end
end

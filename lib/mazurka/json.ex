defmodule Mazurka.JSON do
  defmacro __using__(_) do
    quote do
      def enter(value, vars) do
        Mazurka.JSON.enter(value, vars, __MODULE__)
      end

      def exit(value, vars) do
        Mazurka.JSON.exit(value, vars, __MODULE__)
      end
    end
  end

  alias Mazurka.Resource

  def enter(%Resource.Map{}, vars, _impl) do
    %{map_suffix: [map_suffix | _]} =
      vars =
      Map.update(vars, :map_suffix, [suffix_var(0)], fn suffixes ->
        [suffix_var(length(suffixes)) | suffixes]
      end)

    %{buffer: buffer} = vars

    {quote do
       unquote(map_suffix) = []
       unquote(buffer) = ["}" | unquote(buffer)]
     end, vars}
  end

  def enter(%Resource.Field{}, vars, _impl) do
    %{map_suffix: [map_suffix | _], buffer: buffer} = vars

    {quote do
       unquote(buffer) = [unquote(map_suffix) | unquote(buffer)]
     end, vars}
  end

  def enter(%Resource.Constant{value: value, line: line}, vars, _impl) do
    %{buffer: buffer} = vars

    {quote line: line do
       unquote(buffer) = [
         unquote(Poison.encode!(value))
         | unquote(buffer)
       ]
     end, vars}
  end

  def enter(%Resource.Resolve{body: body, line: line}, vars, _impl) do
    %{buffer: buffer} = vars

    {quote line: line do
       unquote(buffer) = [
         Poison.Encoder.encode(unquote(body), %{})
         | unquote(buffer)
       ]
     end, vars}
  end

  def enter(_value, vars, _impl) do
    {nil, vars}
  end

  def exit(%Resource.Map{}, vars, _impl) do
    %{buffer: buffer, map_suffix: [suffix | map_suffix]} = vars

    {quote do
       _ = unquote(suffix)
       unquote(buffer) = ["{" | unquote(buffer)]
     end, %{vars | map_suffix: map_suffix}}
  end

  def exit(%Resource.Field{name: name}, vars, _impl) do
    %{map_suffix: [map_suffix | _], buffer: buffer} = vars

    {quote do
       unquote(buffer) = [
         unquote(Poison.encode!(name) <> ":") | unquote(buffer)
       ]

       unquote(map_suffix) = ","
     end, vars}
  end

  def exit(_value, vars, _impl) do
    {nil, vars}
  end

  defp suffix_var(id) do
    Macro.var(:"map_suffix_#{id}", __MODULE__)
  end
end

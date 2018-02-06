defmodule Mazurka.Msgpack do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @doc false
      def enter(value, vars) do
        Mazurka.Msgpack.enter(value, vars, __MODULE__)
      end

      @doc false
      def exit(value, vars) do
        Mazurka.Msgpack.exit(value, vars, __MODULE__)
      end
    end
  end

  alias Mazurka.Resource

  def enter(%Resource.Map{}, vars, _impl) do
    %{map_size: [map_size | _]} =
      vars =
      Map.update(vars, :map_size, [map_size_var(0)], fn sizes ->
        [map_size_var(length(sizes)) | sizes]
      end)

    {quote do
       unquote(map_size) = 0
     end, vars}
  end

  def enter(%Resource.Constant{value: value, line: line}, vars, _impl) do
    %{buffer: buffer} = vars

    {quote line: line do
       unquote(buffer) = [
         unquote(pack(value))
         | unquote(buffer)
       ]
     end, vars}
  end

  def enter(%Resource.Resolve{body: body, line: line}, vars, _impl) do
    %{buffer: buffer} = vars

    {quote line: line do
       unquote(buffer) = [
         Msgpax.Packer.pack(unquote(body))
         | unquote(buffer)
       ]
     end, vars}
  end

  def enter(_value, vars, _impl) do
    {nil, vars}
  end

  def exit(%Resource.Map{}, vars, _impl) do
    %{buffer: buffer, map_size: [map_size | map_sizes]} = vars

    {quote do
       unquote(buffer) = [
         case unquote(map_size) do
           s when s < 16 -> <<0b10000000 + s::8>>
           s when s < 0x10000 -> <<0xDE, s::16>>
           s when s < 0x100000000 -> <<0xDF, s::32>>
         end
         | unquote(buffer)
       ]
     end, %{vars | map_size: map_sizes}}
  end

  def exit(%Resource.Field{name: name}, vars, _impl) do
    %{map_size: [map_size | _], buffer: buffer} = vars

    {quote do
       unquote(buffer) = [
         unquote(pack(name)) | unquote(buffer)
       ]

       unquote(map_size) = unquote(map_size) + 1
     end, vars}
  end

  def exit(_value, vars, _impl) do
    {nil, vars}
  end

  defp map_size_var(id) do
    Macro.var(:"map_size_#{id}", __MODULE__)
  end

  defp pack(value) do
    value
    |> Msgpax.Packer.pack()
    |> :erlang.iolist_to_binary()
  end
end

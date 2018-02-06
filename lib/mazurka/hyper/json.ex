defmodule Mazurka.Hyper.JSON do
  defmacro __using__(opts) do
    provides =
      opts[:provides] ||
        Macro.escape([
          {"application", "json", %{}},
          {"application", "hyper+json", %{}}
        ])

    quote do
      @mazurka_mediatypes %Mazurka.Mediatype{
        provides: unquote(provides),
        serializer: unquote(__MODULE__)
      }
    end
  end

  use Mazurka.Serializer
  use Mazurka.JSON
end

# defimpl Mazurka.Hyper.JSON, for: Mazurka.Resource.Action do
#   def serialize(
#         %{
#           conditions: conditions,
#           scope: scope,
#           inputs: inputs,
#           value: %{line: line}
#         },
#         %{conn: conn} = vars
#       ) do
#     buffer = Macro.var(:buffer, __MODULE__)
#     vars = Map.put(vars, :buffer, buffer)

#     {body, vars} =
#       @protocol.serialize(
#         %Mazurka.Resource.Map{
#           conditions: conditions,
#           scope: scope,
#           fields: [
#             %Mazurka.Resource.Field{
#               name: "action",
#               value: %Mazurka.Resource.Constant{
#                 value: "http://example.com"
#               }
#             },
#             %Mazurka.Resource.Field{
#               name: "method",
#               value: %Mazurka.Resource.Constant{
#                 value: "POST"
#               }
#             },
#             %Mazurka.Resource.Field{
#               name: "input",
#               value: %Mazurka.Resource.Map{
#                 line: line,
#                 fields: inputs
#               }
#             }
#           ],
#           line: line
#         },
#         vars
#       )

#     {quote do
#        unquote(buffer) = []
#        unquote(body)
#        {unquote(buffer), unquote(conn)}
#      end, vars}
#   end
# end

# defimpl Mazurka.Hyper.JSON, for: Mazurka.Resource.Input do
#   def serialize(
#         %{
#           conditions: conditions,
#           info: info,
#           name: name,
#           scope: scope,
#           value: value,
#           line: line
#         },
#         vars
#       ) do
#     fields = Map.put(info, :value, value)

#     %Mazurka.Resource.Field{
#       conditions: conditions,
#       name: name,
#       scope: scope,
#       value: %Mazurka.Resource.Map{
#         line: line,
#         fields:
#           for field <- fields, {name, value} = field do
#             %Mazurka.Resource.Field{
#               name: name,
#               value: value,
#               line: line
#             }
#           end
#       },
#       line: line
#     }
#     |> @protocol.serialize(vars)
#   end
# end

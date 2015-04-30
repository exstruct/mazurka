defmodule Mazurka.Compiler do
  def file(src, opts \\ []) do
    {:ok, resources} = :mazurka_dsl.parse_file(src, opts)
    resources
    |> Enum.map(&(Mazurka.Compiler.Resource.compile(&1, src, opts)))
    |> Enum.concat
  end
end

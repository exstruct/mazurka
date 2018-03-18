defmodule Mazurka.Resource.Builder do
  def subject do
    Macro.var(:"@mazurka_subject", nil)
  end

  def eval(module, body, imports \\ nil, env) do
    quote do
      try do
        unquote(subject()) = nil
        import Kernel, except: [@: 1]
        import unquote(Mazurka.Resource.Attribute)

        unquote(
          child(
            module,
            body,
            imports
          )
        )
      rescue
        e in UndefinedFunctionError ->
          # TODO reformat so it's nice
          raise e
      end
    end
    |> Code.eval_quoted(
      [],
      file: env.file,
      line: env.line,
      aliases: env.aliases,
      requires: env.requires,
      functions: env.functions,
      macros: env.macros
    )
    |> elem(0)
  end

  def child(module, body \\ nil, imports \\ nil)

  def child(module, body, imports) when is_atom(module) do
    {:%, [], [module, {:%{}, [], []}]}
    |> child(body, imports)
  end

  def child(struct, body, imports) do
    id = :erlang.unique_integer()
    parent = Macro.var(:"parent_#{id}", __MODULE__)

    quote do
      unquote(parent) = unquote(subject())

      unquote(subject()) = %{
        unquote(struct)
        | line: __ENV__.line
      }

      unquote(imports)
      unquote(body)

      unquote(subject()) =
        unquote(__MODULE__).__append__(
          unquote(parent),
          unquote(subject())
        )
    end
  end

  def __append__(nil, %{children: children} = subject) do
    %{subject | children: :lists.reverse(children)}
  end

  def __append__(%{children: children} = prev, subject) do
    subject =
      case subject do
        %{children: c} ->
          %{subject | children: :lists.reverse(c)}

        _ ->
          subject
      end

    %{prev | children: [subject | children]}
  end
end

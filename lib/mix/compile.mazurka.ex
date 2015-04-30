defmodule Mix.Tasks.Compile.Mazurka do
  use Mix.Task

  @recursive true
  @manifest ".compile.mazurka"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [force: :boolean])

    project      = Mix.Project.config
    options      = project[:mazurka_options] || []
    source_paths = options[:paths] || ["res"]
    compile_path = Mix.Project.compile_path(project)

    files = for src <- source_paths do
      extract_targets(src, compile_path, opts[:force])
    end |> Enum.concat

    mapping = for {file, target, _compile, status} <- files do
      {status, file, target}
    end

    compile_opts = [native: Keyword.get(options, :native, Mix.env == :prod),
                    timeout: Keyword.get(options, :timeout, 5000)]

    Mix.Compilers.Erlang.compile(manifest(), mapping, fn
      input, output ->
        {_, _, compile, _} = :lists.keyfind(input, 1, files)
        case compile.(compile_opts) do
          {name, beam} when is_binary(beam) ->
            File.write!(output, beam)
            {:ok, {name, beam}}
          error ->
            error
        end
    end)
  end

  def manifests, do: [manifest]
  defp manifest, do: Path.join(Mix.Project.manifest_path, @manifest)

  defp extract_targets(src_dir, dest_dir, force) do
    for file <- Mix.Utils.extract_files([src_dir], ["md"]) do
      for {module, compile, type} <- Mazurka.Compiler.file(file, []) do
        source = "#{file} (#{type})"
        target = Path.join(dest_dir, "#{module}.beam")

        if force || Mix.Utils.stale?([file], [target]) do
          {source, target, compile, :stale}
        else
          {source, target, compile, :ok}
        end
      end
    end |> Enum.concat
  end
end

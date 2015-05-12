defmodule Mix.Tasks.Compile.Mazurka do
  use Mix.Task

  @recursive true
  @manifest ".compile.mazurka"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [force: :boolean])

    project      = Mix.Project.config
    options      = project[:mazurka_options] || []
    source_paths = options[:paths] || ["res"]
    erlc_options = project[:erlc_options] || []
    compile_path = Mix.Project.compile_path(project)
    force        = opts[:force]

    compile_opts = [native: Keyword.get(options, :native, Mix.env == :prod),
                    timeout: Keyword.get(options, :timeout, 5000),
                    debug: Keyword.get(options, :debug, false),
                    erlc_options: erlc_options]

    files = for src <- source_paths do
      extract_targets(src, compile_path, force, compile_opts)
    end |> Enum.concat

    mapping = for {file, target, _compile, status} <- files do
      {status, file, target}
    end

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

  defp extract_targets(src_dir, dest_dir, force, opts) do
    for file <- Mix.Utils.extract_files([src_dir], ["md"]) do
      for {module, compile, stale?, type} <- Mazurka.Compiler.file(file, []) do
        source = "#{file} (#{type})"
        target = Path.join(dest_dir, "#{module}.beam")

        if force || stale?.(target, opts) do
          {source, target, compile, :stale}
        else
          {source, target, compile, :ok}
        end
      end
    end |> Enum.concat
  end
end

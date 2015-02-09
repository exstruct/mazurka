defmodule Mix.Tasks.Compile.Mazurka do
  use Mix.Task

  @recursive true
  @manifest ".compile.mazurka"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [force: :boolean])

    project      = Mix.Project.config
    source_paths = project[:mazurka_paths] || ["res"]
    compile_path = Mix.Project.compile_path(project)

    files = for src <- source_paths do
      extract_targets(src, compile_path, opts[:force])
    end |> Enum.concat

    mapping = for {file, target, _resource, status} <- files do
      {status, file, target}
    end

    Mix.Compilers.Erlang.compile(manifest(), mapping, fn
      input, output ->
        dest = Path.dirname(output)
        {_, _, ast, _} = :lists.keyfind(input, 1, files)
        Mazurka.Compiler.compile_resource(ast, input, dest)
    end)
  end

  def manifests, do: [manifest]
  defp manifest, do: Path.join(Mix.Project.manifest_path, @manifest)

  defp extract_targets(src_dir, dest_dir, force) do
    files = Mix.Utils.extract_files(List.wrap(src_dir), List.wrap("md"))

    for file <- files do
      {:ok, resources} = Mazurka.Compiler.parse(file, [])

      for resource <- resources do
        target = Path.join(dest_dir, "#{resource[:name]}.beam")

        if force || Mix.Utils.stale?([file], [target]) do
          {file, target, resource, :stale}
        else
          {file, target, resource, :ok}
        end
      end
    end |> Enum.concat
  end
end

defmodule Mazurka.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mazurka,
      version: "2.0.0",
      elixir: "~> 1.5",
      description: "hypermedia api toolkit",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.circle": :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      package: package(),
      deps: deps(),
      docs: [extras: extras(), logo: "extra/logo.png"]
    ]
  end

  def application do
    [
      extra_applications:
        case Mix.env() do
          :prod ->
            []

          _ ->
            [:poison, :msgpax, :plug]
        end
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.1", optional: true},
      {:msgpax, "~> 2.1", optional: true},
      {:plug, "~> 1.4", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:rl, "~> 0.1", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:dialyzex, "~> 1.1.0", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Cameron Bytheway"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/exstruct/mazurka"}
    ]
  end

  def extras() do
    if Mix.env() == :dev do
      [
        {"Tutorials", Path.wildcard("test/**/*.md")}
      ]
      |> Enum.flat_map(fn {group, files} ->
        Enum.map(files, fn file ->
          {file, [group: group]}
        end)
      end)
    else
      []
    end
  end
end

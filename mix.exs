defmodule Mazurka.Mixfile do
  use Mix.Project

  def project do
    [app: :mazurka,
     version: "0.2.4",
     elixir: "~> 1.0",
     description: "hypermedia api toolkit",
     package: package,
     elixirc_paths: ["lib"] ++ dev_paths(Mix.env),
     deps: deps]
  end

  ## Load the fixtures for easy development
  defp dev_paths(:dev) do
    ["test/mazurka_test"]
  end
  defp dev_paths(_), do: []

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:plug, ">= 0.9.0"},
     {:poison, ">= 1.4.0"},
     {:etude, "~> 0.2.0"},
     {:parse_trans, github: "uwiger/parse_trans", optional: true},
     {:mazurka_dsl, "~> 0.1.1", optional: true},
     {:mimetype_parser, "~> 0.1.0"},
     {:cowboy, "~> 1.0.0", only: :dev},
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.7", only: :dev}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     contributors: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mazurka/mazurka"}]
  end
end

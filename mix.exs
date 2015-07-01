defmodule Mazurka.Mixfile do
  use Mix.Project

  def project do
    [app: :mazurka,
     version: "0.1.10",
     elixir: "~> 1.0",
     description: "hypermedia api toolkit",
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:plug, ">= 0.9.0"},
     {:poison, ">= 1.4.0"},
     {:etude, path: "../../camshaft/etude"},
     {:parse_trans, github: "uwiger/parse_trans", optional: true},
     {:mazurka_mediatype, "~> 0.1.0"},
     {:mazurka_dsl, "~> 0.1.0"},
     {:mimetype_parser, "~> 0.1.0"}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     contributors: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mazurka/mazurka"}]
  end
end

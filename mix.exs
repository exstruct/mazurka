defmodule Mazurka.Mixfile do
  use Mix.Project

  def project do
    [app: :mazurka,
     version: "0.3.30",
     elixir: "~> 1.0",
     description: "hypermedia api toolkit",
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:ecto, ">= 1.0.0"},
     {:plug, ">= 0.9.0"},
     {:poison, ">= 1.4.0"},
     {:etude, "~> 0.3.7"},
     {:xml_builder, "~> 0.0.8"},
     {:parse_trans, github: "uwiger/parse_trans", optional: true},
     {:mazurka_dsl, "~> 0.1.1", optional: true},
     {:mimetype_parser, "~> 0.1.0"},
     {:cowboy, "~> 1.0.0", only: :dev},
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.7", only: :dev}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mazurka/mazurka"}]
  end
end

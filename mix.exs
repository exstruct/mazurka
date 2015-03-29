defmodule Mazurka.Mixfile do
  use Mix.Project

  def project do
    [app: :mazurka,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:plug, ">= 0.9.0"},
     {:expr, git: "https://github.com/camshaft/expr.git"},
     {:mazurka_dsl, git: "https://github.com/mazurka/mazurka_dsl.git"},
     {:mimetype_parser, git: "https://github.com/camshaft/mimetype_parser"}]
  end
end

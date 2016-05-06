defmodule Mazurka.Mixfile do
  use Mix.Project

  def project do
    [app: :mazurka,
     version: "0.3.34",
     elixir: "~> 1.0",
     description: "hypermedia api toolkit",
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
       "coveralls": :test,
       "coveralls.circle": :test,
       "coveralls.detail": :test,
       "coveralls.html": :test
     ],
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:mimetype_parser, "~> 0.1.0"},
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.7", only: :dev},
     {:mix_test_watch, "~> 0.2", only: :dev},
     {:excoveralls, "~> 0.5.1", only: :test},]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mazurka/mazurka"}]
  end
end

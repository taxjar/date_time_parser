defmodule DateTimeParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :date_time_parser,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:nimble_parsec, "~> 0.5.0", runtime: false},
      {:timex, "~> 3.1"},
      {:benchee, "~> 1.0", only: [:dev]},
      {:credo, "~> 1.0", only: [:dev]}
    ]
  end
end

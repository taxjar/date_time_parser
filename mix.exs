defmodule DateTimeParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :date_time_parser,
      version: "0.1.0",
      elixir: ">= 1.3.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [tests: :test],
      deps: deps() ++ dev_deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps() do
    [
      {:nimble_parsec, "~> 0.5.0", runtime: false},
      {:timex, "~> 3.2"}
    ]
  end

  defp dev_deps() do
    cond do
      Version.match?(System.version(), ">= 1.6.0") ->
        [
          {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},
          {:credo, "~> 1.0", only: [:dev, :test]}
        ]

      Version.match?(System.version(), ">= 1.5.0") ->
        [
          {:credo, "~> 1.0", only: [:dev, :test]}
        ]

      true ->
        []
    end
  end

  defp aliases() do
    [
      tests: ["test", "credo --strict"]
    ]
  end
end

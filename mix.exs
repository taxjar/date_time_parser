defmodule DateTimeParser.MixProject do
  use Mix.Project
  @version "0.1.4"

  def project do
    [
      app: :date_time_parser,
      name: "DateTimeParser",
      version: @version,
      homepage_url: "https://hexdocs.pm/date_time_parser",
      source_url: "https://github.com/taxjar/date_time_parser",
      elixir: ">= 1.3.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      package: package(),
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        tests: :test,
        benchmark: :bench,
        profile: :bench
      ],
      deps: deps(),
      description:
        "Parse a string into `%DateTime{}`, `%NaiveDateTime{}`, `%Time{}`, or `%Date{}`"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "CODE_OF_CONDUCT*",
        "CHANGELOG*",
        "README*",
        "LICENSE*",
        "EXAMPLES*"
      ],
      maintainers: ["David Bernheisel"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/taxjar/date_time_parser",
        "Readme" => "https://github.com/taxjar/date_time_parser/blob/#{@version}/README.md",
        "Changelog" => "https://github.com/taxjar/date_time_parser/blob/#{@version}/CHANGELOG.md"
      }
    ]
  end

  defp deps() do
    [
      {:nimble_parsec, "~> 0.5.0", runtime: false},
      {:timex, "~> 3.2"},
      {:exprof, "~> 0.2.0", only: :bench}
    ]
    |> add_dep_if({:benchee, "~> 1.0", only: [:bench], runtime: false}, ">= 1.6.0")
    |> add_dep_if({:credo, "~> 1.1", only: [:dev, :test], runtime: false}, ">= 1.5.0")
    |> add_dep_if({:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false}, ">= 1.6.0")
    |> add_dep_if({:ex_doc, "~> 0.20.0", only: :dev, runtime: false}, ">= 1.7.0")
  end

  defp add_dep_if(deps, dep, version) do
    if Version.match?(System.version(), version) do
      [dep | deps]
    else
      deps
    end
  end

  defp docs() do
    [
      main: "DateTimeParser",
      source_ref: @version,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "EXAMPLES.md",
        "LICENSE.md"
      ]
    ]
  end

  defp aliases() do
    [
      tests: [
        "compile --force --warnings-as-errors",
        "test",
        "credo --strict"
      ],
      profile: ["run bench/profile.exs"],
      benchmark: [
        "run bench/self.exs",
        "cmd ruby bench/ruby.rb",
        "cmd ruby bench/rails.rb"
      ]
    ]
  end
end

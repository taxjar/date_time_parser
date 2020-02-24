defmodule DateTimeParser.MixProject do
  use Mix.Project
  @version "1.0.0"

  def project do
    [
      app: :date_time_parser,
      name: "DateTimeParser",
      version: @version,
      homepage_url: "https://hexdocs.pm/date_time_parser",
      source_url: "https://github.com/taxjar/date_time_parser",
      elixir: ">= 1.4.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs"] ++ plt_files(ci: System.get_env("CI")),
      package: package(),
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        dialyzer: :test,
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
    |> add_dep_if({:dialyxir, "~> 1.0.0-rc.7", only: [:dev, :test], runtime: false}, ">= 1.6.0")
    |> add_dep_if({:ex_doc, "~> 0.20", only: :dev, runtime: false}, ">= 1.7.0")
  end

  defp docs() do
    [
      main: "DateTimeParser",
      source_ref: @version,
      extras: [
        "pages/Future-UTC-DateTime.md",
        "CHANGELOG.md",
        "EXAMPLES.md",
        "LICENSE.md"
      ]
    ]
  end

  defp tests() do
    []
    |> add_command_if("compile --force --warnings-as-errors", true)
    |> add_command_if("format --check-formatted", ">= 1.6.0")
    |> add_command_if("credo --strict", ">= 1.6.0")
    |> add_command_if("test", true)
    |> add_command_if("dialyzer", ">= 1.6.0")
  end

  defp aliases() do
    [
      tests: tests(),
      profile: ["run bench/profile.exs"],
      benchmark: [
        "run bench/self.exs",
        "cmd ruby bench/ruby.rb",
        "cmd ruby bench/rails.rb"
      ]
    ]
  end

  defp add_dep_if(deps, dep, version) do
    if Version.match?(System.version(), version) do
      [dep | deps]
    else
      deps
    end
  end

  defp add_command_if(commands, command, true), do: commands ++ [command]

  defp add_command_if(commands, command, version) do
    if Version.match?(System.version(), version) do
      commands ++ [command]
    else
      commands
    end
  end

  defp plt_files(ci: "true") do
    [
      plt_core_path: ".cache/plt-core",
      plt_file: {:no_warn, ".cache/plt-project/date_time_parser.plt"}
    ]
  end

  defp plt_files(_), do: []
end

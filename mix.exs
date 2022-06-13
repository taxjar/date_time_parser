defmodule DateTimeParser.MixProject do
  use Mix.Project
  @version "1.1.4"

  def project do
    [
      app: :date_time_parser,
      name: "DateTimeParser",
      version: @version,
      homepage_url: "https://hexdocs.pm/date_time_parser",
      source_url: "https://github.com/taxjar/date_time_parser",
      elixir: ">= 1.4.0",
      # When on Elixir 1.7+, enable inline: true for nimble parsec
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
      description: "Parse a string into DateTime, NaiveDateTime, Time, or Date struct."
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
    [{:exprof, "~> 0.2.0", only: :bench}]
    |> add_if({:timex, ">= 3.2.1 and <= 3.7.2"}, ">= 1.6.0")
    |> add_if({:timex, "< 3.2.1"}, "< 1.6.0")
    |> add_if({:gettext, "<= 0.16.1"}, "< 1.6.0")
    |> add_if({:benchee, "~> 1.0", only: [:bench], runtime: false}, ">= 1.6.0")
    |> add_if({:credo, "~> 1.1", only: [:dev, :test], runtime: false}, ">= 1.5.0")
    |> add_if({:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}, ">= 1.6.0")
    |> add_if({:ex_doc, "~> 0.20", only: :dev, runtime: false}, ">= 1.7.0")
    |> add_if({:nimble_parsec, "~> 0.5.0", only: [:dev, :test], runtime: false}, "< 1.6.0")
    |> add_if({:nimble_parsec, "~> 1.0", only: [:dev, :test], runtime: false}, ">= 1.6.0")
  end

  defp docs() do
    [
      main: "DateTimeParser",
      source_ref: @version,
      extras: [
        "pages/Future-UTC-DateTime.md",
        "CHANGELOG.md",
        "EXAMPLES.livemd",
        "LICENSE.md"
      ]
    ]
  end

  defp tests() do
    []
    |> add_if("compile.nimble", !System.get_env("CI"))
    |> add_if("format --check-formatted", ">= 1.10.0")
    |> add_if("credo --strict", ">= 1.6.0")
    |> add_if("test", true)
  end

  defp aliases() do
    [
      "compile.nimble": [
        "cmd rm -f lib/combinators.ex",
        "nimble_parsec.compile lib/combinators.ex.exs",
        "compile"
      ],
      tests: tests(),
      profile: ["run bench/profile.exs"],
      benchmark: [
        "run bench/self.exs",
        "cmd ruby bench/ruby.rb",
        "cmd ruby bench/rails.rb"
      ]
    ]
  end

  defp add_if(commands, command, true), do: commands ++ [command]
  defp add_if(commands, _command, ""), do: commands

  defp add_if(commands, command, version) when is_binary(version) do
    add_if(commands, command, Version.match?(System.version(), version))
  end

  defp add_if(commands, _command, _), do: commands
end

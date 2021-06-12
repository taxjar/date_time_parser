defmodule DateTimeParser.MixProject do
  use Mix.Project
  @version "1.1.1"

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
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs"] ++ plt_file(),
      package: package(),
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        typespecs: :test,
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
    [{:exprof, "~> 0.2.0", only: :bench}]
    |> add_if({:nimble_parsec, "~> 0.5.0", runtime: false}, "< 1.6.0")
    |> add_if({:nimble_parsec, "~> 1.0", runtime: false}, ">= 1.6.0")
    |> add_if({:timex, ">= 3.2.1 and <= 3.7.2"}, ">= 1.6.0")
    |> add_if({:timex, "< 3.2.1"}, "< 1.6.0")
    |> add_if({:gettext, "<= 0.16.1"}, "< 1.6.0")
    |> add_if({:benchee, "~> 1.0", only: [:bench], runtime: false}, ">= 1.6.0")
    |> add_if({:credo, "~> 1.1", only: [:dev, :test], runtime: false}, ">= 1.5.0")
    |> add_if({:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false}, ">= 1.6.0")
    |> add_if({:ex_doc, "~> 0.20", only: :dev, runtime: false}, ">= 1.7.0")
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
    |> add_if("compile --force --warnings-as-errors", !System.get_env("CI"))
    |> add_if("format --check-formatted", ">= 1.10.0")
    |> add_if("credo --strict", ">= 1.6.0")
    |> add_if("test", true)
    |> typespecs()
  end

  defp typespecs(commands \\ []) do
    # For some reason, typespecs on 20 spin forever, so restrict to 21+
    commands
    |> add_if("dialyzer", Version.match?(System.otp_release() <> ".0.0", ">= 21.0.0"))
  end

  defp aliases() do
    [
      tests: tests(),
      typespecs: typespecs(),
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

  @plt_path Path.join(["priv", "plts"])
  defp plt_file() do
    if System.get_env("CI") == "true" do
      :ok = File.mkdir_p(@plt_path)

      [
        plt_file: {:no_warn, Path.join([@plt_path, "project.plt"])},
        plt_core_path: @plt_path
      ]
    else
      []
    end
  end
end

if System.get_env("CI") == "true" do
  "test-results/exunit"
  |> Path.relative()
  |> File.mkdir_p!()

  ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
end

ExUnit.start()

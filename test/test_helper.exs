if System.get_env("CI") == "true" do
  "test-results/exunit"
  |> Path.relative()
  |> File.mkdir_p!()

  ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
end

example_file = "EXAMPLES.md"
File.rm(example_file)
File.write!(example_file, """
# Examples

|**Method**|**Input**|**Output (ISO 8601)**|
|:--------:|:-------:|:--------:|
""")

ExUnit.start()

alias DateTimeParserTest.Recorder

if System.get_env("CI") == "true" do
  "test-results/exunit"
  |> Path.relative()
  |> File.mkdir_p!()

  ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
end

{:ok, _recorder_pid} = Recorder.start_link()

write_examples = fn
  %{excluded: excluded, skipped: skipped} when excluded > 0 or skipped > 0 ->
    :ok

  _ ->
    Recorder.write_results()
end

if Version.match?(System.version(), ">= 1.8.0"), do: ExUnit.after_suite(write_examples)
ExUnit.start()

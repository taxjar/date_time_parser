alias DateTimeParserTest.Recorder

{:ok, _recorder_pid} = Recorder.start_link()

write_examples = fn
  %{excluded: excluded, skipped: skipped} when excluded > 0 or skipped > 0 ->
    :ok

  _ ->
    Recorder.write_results()
end

if Version.match?(System.version(), ">= 1.8.0"), do: ExUnit.after_suite(write_examples)
ExUnit.start()

require DateTimeParser

Benchee.run(%{
  "parse_datetime" => fn input ->
    Enum.map(input, &DateTimeParser.parse_datetime/1)
  end,

  "parse_date" => fn input ->
    Enum.map(input, &DateTimeParser.parse_date/1)
  end,

  "parse_time" => fn input ->
    Enum.map(input, &DateTimeParser.parse_time/1)
  end
}, [
  inputs: %{
    "date_formats_samples.txt" =>
      "test/fixture/date_formats_samples.txt"
      |> File.read!()
      |> String.split("\n")
  },
  save: [file: "benchmark.benchee", tag: Date.to_iso8601(DateTime.utc_now())],
  load: "benchmark.benchee",
  after_scenario: fn input ->
    input
    |> Enum.reduce(0, fn i, errors ->
      case DateTimeParser.parse_datetime(i) do
        {:ok, _} -> errors
        {:error, _} -> errors + 1
      end
    end)
    |> IO.inspect(label: "Failed to parse")
  end
])

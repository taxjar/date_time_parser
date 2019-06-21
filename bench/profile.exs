defmodule Profiler do
  import ExProf.Macro
  require DateTimeParser

  def run(samples) do
    {results, _return} = profile do
      Enum.map(samples, &DateTimeParser.parse_datetime/1)
    end

    results
    |> Enum.sort_by(fn %{time: total_time, percent: total_percent, us_per_call: call_cost} ->
      [total_time, total_percent, call_cost]
    end)
    |> Enum.reverse()
    |> Enum.take(10)
    |> IO.inspect(label: "TOP OFFENDERS")
  end
end

samples = "test/fixture/date_formats_samples.txt" |> File.read!() |> String.split("\n")
Profiler.run(samples)

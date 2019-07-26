defmodule DateTimeParser.DateTime do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Combinators.Date
  import DateTimeParser.Combinators.DateTime

  def parse_epoch(string) do
    with true <- String.contains?(string, "."),
         [second, subsecond] <- String.split(string, ".", trim: true),
         second <- String.to_integer(second),
         {:ok, datetime} <- DateTime.from_unix(second),
         subsecond <- String.slice(subsecond, 0, 6),
         subsecond_int <- subsecond |> String.pad_trailing(6, "0") |> String.to_integer() do
      {
        :ok,
        %{datetime | microsecond: {subsecond_int, :erlang.size(subsecond)}}
      }
    else
      false ->
        string |> String.to_integer() |> DateTime.from_unix()
    end
  end

  defparsec(
    :parse,
    vocal_day()
    |> optional()
    |> choice([
      vocal_month_day_time_year(),
      formal_date_time(),
      formal_date()
    ])
  )

  defparsec(
    :parse_us,
    vocal_day()
    |> optional()
    |> choice([
      vocal_month_day_time_year(),
      us_date_time(),
      us_date()
    ])
  )
end

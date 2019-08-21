defmodule DateTimeParser.DateTime do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Combinators.Date
  import DateTimeParser.Combinators.DateTime
  import DateTimeParser.Formatters, only: [format_token: 2, clean: 1]

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

  def from_tokens(tokens) do
    Map.merge(
      NaiveDateTime.utc_now(),
      clean(%{
        year: format_token(tokens, :year),
        month: format_token(tokens, :month),
        day: format_token(tokens, :day),
        hour: format_token(tokens, :hour) || 0,
        minute: format_token(tokens, :minute) || 0,
        second: format_token(tokens, :second) || 0,
        microsecond: format_token(tokens, :microsecond) || {0, 0}
      })
    )
  end

  def timezone_from_tokens(tokens) do
    with zone <- format_token(tokens, :zone_abbr),
         offset <- format_token(tokens, :utc_offset),
         true <- Enum.any?([zone, offset]) do
      Timex.Timezone.get(offset || zone)
    end
  end

  def from_naive_datetime_and_timezone(naive_datetime, nil), do: naive_datetime

  def from_naive_datetime_and_timezone(naive_datetime, timezone_info) do
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> Map.merge(%{
      std_offset: timezone_info.offset_std,
      utc_offset: timezone_info.offset_utc,
      zone_abbr: timezone_info.abbreviation,
      time_zone: timezone_info.full_name
    })
  end
end

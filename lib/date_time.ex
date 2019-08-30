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

  def from_tokens(tokens, opts) do
    parsed_values = clean(%{
      year: format_token(tokens, :year),
      month: format_token(tokens, :month),
      day: format_token(tokens, :day),
      hour: format_token(tokens, :hour),
      minute: format_token(tokens, :minute),
      second: format_token(tokens, :second),
      microsecond: format_token(tokens, :microsecond)
    })

    case Keyword.get(opts, :assume_time, false) do
      false ->
        NaiveDateTime.new(
          parsed_values[:year],
          parsed_values[:month],
          parsed_values[:day],
          parsed_values[:hour],
          parsed_values[:minute],
          parsed_values[:second] || 0,
          parsed_values[:microsecond] || {0, 0}
        )

      %Time{} = assumed_time ->
        assume_time(parsed_values, assumed_time)

      true ->
        assume_time(parsed_values, ~T[00:00:00])
    end
  end

  defp assume_time(parsed_values, %Time{} = time) do
    NaiveDateTime.new(
      parsed_values[:year],
      parsed_values[:month],
      parsed_values[:day],
      parsed_values[:hour] || time.hour,
      parsed_values[:minute] || time.minute,
      parsed_values[:second] || time.second,
      parsed_values[:microsecond] || time.microsecond
    )
  end

  defp timezone_from_tokens(tokens) do
    with zone <- format_token(tokens, :zone_abbr),
         offset <- format_token(tokens, :utc_offset),
         true <- Enum.any?([zone, offset]) do
      Timex.Timezone.get(offset || zone)
    end
  end

  def from_naive_datetime_and_tokens(naive_datetime, tokens) do
    with timezone when not is_nil(timezone) <- tokens[:zone_abbr] || tokens[:utc_offset],
         %{} = timezone_info <- timezone_from_tokens(tokens) do
      naive_datetime
      |> DateTime.from_naive!("Etc/UTC")
      |> Map.merge(%{
        std_offset: timezone_info.offset_std,
        utc_offset: timezone_info.offset_utc,
        zone_abbr: timezone_info.abbreviation,
        time_zone: timezone_info.full_name
      })
    else
      _ -> naive_datetime
    end
  end
end

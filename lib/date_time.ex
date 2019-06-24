defmodule DateTimeParser.DateTime do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Combinators.Date
  import DateTimeParser.Combinators.DateTime

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

defmodule DateTimeParser.Date do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Combinators.Date

  defparsec(
    :parse,
    vocal_day()
    |> optional()
    |> concat(formal_date())
  )

  defparsec(
    :parse_us,
    vocal_day()
    |> optional()
    |> concat(us_date())
  )
end

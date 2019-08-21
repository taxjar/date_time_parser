defmodule DateTimeParser.Date do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Combinators.Date
  import DateTimeParser.Formatters, only: [format_token: 2]

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

  def from_tokens(tokens) do
    Date.new(
      format_token(tokens, :year) || 0,
      format_token(tokens, :month) || 0,
      format_token(tokens, :day) || 0
    )
  end
end

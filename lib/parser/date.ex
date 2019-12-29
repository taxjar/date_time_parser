defmodule DateTimeParser.Parser.Date do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Combinators.Date
  import DateTimeParser.Formatters, only: [format_token: 2, clean: 1]

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

  def from_tokens(tokens, opts) do
    parsed_values =
      clean(%{
        year: format_token(tokens, :year),
        month: format_token(tokens, :month),
        day: format_token(tokens, :day)
      })

    case Keyword.get(opts, :assume_date, false) do
      %Date{} = date ->
        {:ok, Map.merge(date, parsed_values)}

      false ->
        Date.new(parsed_values[:year], parsed_values[:month], parsed_values[:day])

      true ->
        {:ok, Map.merge(Date.utc_today(), parsed_values)}
    end
  end
end

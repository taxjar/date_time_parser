defmodule DateTimeParser.Parser.DateTimeUS do
  @moduledoc """
  Tokenizes the string for both date and time formats. This prioritizes the US format for
  representing dates.
  """
  @behaviour DateTimeParser.Parser

  import NimbleParsec
  import DateTimeParser.Combinators.Date
  import DateTimeParser.Combinators.DateTime

  defparsecp(
    :do_parse,
    vocal_day()
    |> optional()
    |> choice([
      vocal_month_day_time_year(),
      us_date_time(),
      us_date()
    ])
  )

  @impl DateTimeParser.Parser
  def preflight(parser), do: {:ok, parser}

  @impl DateTimeParser.Parser
  def parse(%{string: string} = parser) do
    case do_parse(string) do
      {:ok, tokens, _, _, _, _} ->
        DateTimeParser.Parser.DateTime.from_tokens(parser, tokens)

      _ ->
        {:error, :failed_to_parse}
    end
  end
end

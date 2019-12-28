defmodule DateTimeParser.Parser.DateUS do
  @moduledoc false
  @behaviour DateTimeParser.Parser

  import NimbleParsec
  import DateTimeParser.Combinators.Date

  defparsecp(
    :do_parse,
    vocal_day()
    |> optional()
    |> concat(us_date())
  )

  @impl DateTimeParser.Parser
  def preflight(parser), do: {:ok, parser}

  @impl DateTimeParser.Parser
  def parse(%{string: string} = parser) do
    case do_parse(string) do
      {:ok, tokens, _, _, _, _} ->
        DateTimeParser.Parser.Date.from_tokens(parser, tokens)

      _ ->
        {:error, :failed_to_parse}
    end
  end
end

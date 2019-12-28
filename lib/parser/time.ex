defmodule DateTimeParser.Time do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Combinators.Time
  import DateTimeParser.Formatters, only: [format_token: 2]

  defparsec(:parse, time())

  def from_tokens(tokens) do
    Time.new(
      format_token(tokens, :hour) || 0,
      format_token(tokens, :minute) || 0,
      format_token(tokens, :second) || 0,
      format_token(tokens, :microsecond) || {0, 0}
    )
  end
end

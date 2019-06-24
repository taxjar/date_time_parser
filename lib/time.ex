defmodule DateTimeParser.Time do
  @moduledoc false
  import NimbleParsec
  import DateTimeParser.Combinators.Time

  defparsec(:parse, time())
end

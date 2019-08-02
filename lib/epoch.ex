defmodule DateTimeParser.Epoch do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Combinators.Epoch

  defparsec(:parse, unix_epoch())
end

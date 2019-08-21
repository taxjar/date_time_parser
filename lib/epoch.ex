defmodule DateTimeParser.Epoch do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Formatters, only: [format: 1]
  import DateTimeParser.Combinators.Epoch

  defparsec(:parse, unix_epoch())

  def from_tokens(tokens) do
    with {:ok, datetime} <- DateTime.from_unix(tokens[:unix_epoch]) do
      case tokens[:unix_epoch_subsecond] do
        nil ->
          datetime

        subsecond ->
          truncated_subsecond =
            subsecond
            |> Integer.digits()
            |> Enum.take(6)
            |> Integer.undigits()

          %{datetime | microsecond: format({:microsecond, truncated_subsecond})}
      end
    end
  end
end

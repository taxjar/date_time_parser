defmodule DateTimeParser.Epoch do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Formatters, only: [format: 1]
  import DateTimeParser.Combinators.Epoch

  defparsec(:parse, unix_epoch())

  def from_tokens(tokens) do
    IO.inspect(tokens, label: "Tokens:")
    has_subsecond = !is_nil(tokens[:unix_epoch_subsecond])

    with pos_or_neg <- sign(tokens[:sign]),
         seconds when not is_nil(seconds) <- tokens[:unix_epoch],
         seconds <- calculate_seconds(seconds, pos_or_neg, has_subsecond),
         {:ok, datetime} <-
           DateTime.from_unix(seconds) do
      case tokens[:unix_epoch_subsecond] do
        nil ->
          {:ok, datetime}

        subsecond ->
          truncated_subsecond =
            subsecond
            |> Integer.digits()
            |> Enum.take(6)
            |> Integer.undigits()
            |> IO.inspect(label: "Subseconds")
            |> calculate_subseconds(pos_or_neg)

          {:ok, %{datetime | microsecond: format({:microsecond, truncated_subsecond})}}
      end
    end
  end

  defp calculate_seconds(seconds, -1, true) do
    IO.inspect(seconds, label: "Seconds pre sub")
    (-1 * (seconds + 1)) |> IO.inspect(label: "seconds post sub")
  end

  defp calculate_seconds(seconds, -1, false), do: -1 * seconds
  defp calculate_seconds(seconds, 1, _), do: seconds

  defp calculate_subseconds(subseconds, -1), do: 1.0 - subseconds
  defp calculate_subseconds(subseconds, 1), do: subseconds

  defp sign("-"), do: -1
  defp sign(_), do: 1
end

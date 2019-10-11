defmodule DateTimeParser.Epoch do
  @moduledoc false

  import NimbleParsec
  import DateTimeParser.Formatters, only: [format: 1]
  import DateTimeParser.Combinators.Epoch

  defparsec(:parse, unix_epoch())

  def from_tokens(tokens) do
    with pos_or_neg <- sign(tokens[:sign]),
         seconds when not is_nil(seconds) <- tokens[:unix_epoch],
         seconds <- pos_or_neg * seconds,
         {:ok, datetime} <- DateTime.from_unix(seconds) do
      case tokens[:unix_epoch_subsecond] do
        nil ->
          {:ok, datetime}

        subsecond ->
          truncated_subsecond =
            subsecond
            |> Integer.digits()
            |> Enum.take(6)
            |> Integer.undigits()

          {:ok, %{datetime | microsecond: format({:microsecond, truncated_subsecond})}}
      end
    end
  end

  defp sign("-"), do: -1
  defp sign(_), do: 1
end

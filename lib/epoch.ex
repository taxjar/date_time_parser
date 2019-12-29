defmodule DateTimeParser.Epoch do
  @moduledoc false

  @token_key :unix_epoch
  @max_subsecond_digits 6

  def parse(%{"sign" => sign, "seconds" => raw_seconds, "subseconds" => raw_subseconds}) do
    is_negative = if sign == "-", do: true, else: false
    has_subseconds = if raw_subseconds == "", do: false, else: true

    with {:ok, seconds} <- parse_seconds(raw_seconds, is_negative, has_subseconds),
         {:ok, subseconds} <- parse_subseconds(raw_subseconds, is_negative) do
      {:ok, [{@token_key, {seconds, subseconds}}], nil, nil, nil, nil}
    end
  end

  @spec parse_seconds(String.t(), boolean(), boolean()) :: {:ok, integer()}
  defp parse_seconds(raw_seconds, is_negative, has_subseconds)

  defp parse_seconds(raw_seconds, true, true) do
    with {:ok, seconds} <- parse_seconds(raw_seconds, true, false) do
      {:ok, seconds - 1}
    end
  end

  defp parse_seconds(raw_seconds, true, false) do
    with {:ok, seconds} <- parse_seconds(raw_seconds, false, false) do
      {:ok, seconds * -1}
    end
  end

  defp parse_seconds(raw_seconds, false, _) do
    with {seconds, ""} <- Integer.parse(raw_seconds) do
      {:ok, seconds}
    end
  end

  @spec parse_subseconds(String.t(), boolean()) :: {:ok, {integer(), integer()}}
  defp parse_subseconds(raw_subseconds, is_negative)

  defp parse_subseconds("", _), do: {:ok, {0, 0}}

  defp parse_subseconds(raw_subseconds, true) do
    with {:ok, {truncated_microseconds, number_of_subsecond_digits}} <-
           parse_subseconds(raw_subseconds, false) do
      negative_truncated_microseconds =
        if truncated_microseconds > 0 do
          ((1 * :math.pow(10, 6)) |> trunc()) - truncated_microseconds
        else
          truncated_microseconds
        end

      {:ok, {negative_truncated_microseconds, number_of_subsecond_digits}}
    end
  end

  defp parse_subseconds(raw_subseconds, false) do
    {subseconds, ""} = Float.parse("0.#{raw_subseconds}")
    microseconds = (subseconds * :math.pow(10, 6)) |> trunc()

    truncated_microseconds =
      microseconds
      |> Integer.digits()
      |> Enum.take(@max_subsecond_digits)
      |> Integer.undigits()

    number_of_subsecond_digits = min(String.length(raw_subseconds), @max_subsecond_digits)

    {:ok, {truncated_microseconds, number_of_subsecond_digits}}
  end

  def from_tokens(tokens) do
    {seconds, microseconds} = tokens[@token_key]

    with {:ok, datetime} <- DateTime.from_unix(seconds) do
      {:ok, %{datetime | microsecond: microseconds}}
    end
  end
end

defmodule DateTimeParser.Epoch do
  @moduledoc false

  @token_key :unix_epoch
  @max_subsecond_digits 6

  def parse(%{"sign" => sign, "seconds" => raw_seconds, "subseconds" => raw_subseconds}) do
    is_negative = if sign == "-", do: true, else: false

    with {seconds, ""} <- Integer.parse(raw_seconds) do
      seconds = if is_negative, do: seconds * -1, else: seconds

      parsed_epoch =
        case(raw_subseconds) do
          "" ->
            {seconds, {0, 0}}

          raw_subseconds ->
            {subseconds, ""} = Float.parse("0.#{raw_subseconds}")
            microseconds = (subseconds * :math.pow(10, 6)) |> trunc()

            truncated_microseconds =
              microseconds
              |> Integer.digits()
              |> Enum.take(@max_subsecond_digits)
              |> Integer.undigits()

            number_of_subsecond_digits = min(String.length(raw_subseconds), @max_subsecond_digits)

            if is_negative do
              truncated_microseconds = 1_000_000 - truncated_microseconds
              {seconds - 1, {truncated_microseconds, number_of_subsecond_digits}}
            else
              {seconds, {truncated_microseconds, number_of_subsecond_digits}}
            end
        end

      {:ok, [{@token_key, parsed_epoch}], nil, nil, nil, nil}
    end
  end

  def from_tokens(tokens) do
    {seconds, microseconds} = tokens[@token_key]

    with {:ok, datetime} <- DateTime.from_unix(seconds) do
      {:ok, %{datetime | microsecond: microseconds}}
    end
  end
end

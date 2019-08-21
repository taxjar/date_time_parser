defmodule DateTimeParser.Serial do
  @moduledoc false

  def parse(string) do
    with {float, _} <- Float.parse(string) do
      {:ok, [serial: float], nil, nil, nil, nil}
    end
  end

  def from_tokens(tokens) do
    with {serial_date, serial_time} <- split_float(tokens[:serial]),
         {:ok, time} <- time_from_serial(serial_time),
         {:ok, date} <- date_from_serial(serial_date) do
      Map.merge(date, Map.from_struct(time))
    end
  end

  def time_from_serial(0.0), do: Time.from_erl({0, 0, 0})

  def time_from_serial(serial_time) do
    {hours, min_fraction} = split_float(serial_time * 24)
    {minutes, sec_fraction} = split_float(min_fraction * 60)
    {seconds, _microseconds} = split_float(sec_fraction * 60)

    Time.from_erl({hours, minutes, seconds})
  end

  def date_from_serial(nil), do: :error

  def date_from_serial(serial_date) do
    {{1899, 12, 31}, {0, 0, 0}}
    |> :calendar.datetime_to_gregorian_seconds()
    |> Kernel.+(serial_date * 86_400)
    |> adjust_for_lotus_bug
    |> :calendar.gregorian_seconds_to_datetime()
    |> NaiveDateTime.from_erl()
  end

  def split_float(integer) when is_integer(integer), do: split_float(integer / 1)

  def split_float(float) when float >= 0 do
    whole = float |> Float.floor() |> round()
    {whole, float - whole}
  end

  def split_float(float) when float < 0 do
    whole = abs(float) |> Float.floor() |> round()
    fraction = 1 - (abs(float) - whole)
    fraction = if fraction == 1.0, do: 0.0, else: fraction
    {whole * -1, fraction}
  end

  # https://en.wikipedia.org/wiki/Leap_year_bug
  # Microsoft Excel has, since its earliest versions, incorrectly considered 1900 to be a leap year,
  # and therefore that February 29, 1900 comes between February 28 and March 1 of that year. The bug
  # originated from Lotus 1-2-3, and was purposely implemented in Excel for the purpose of backward
  # compatibility. Microsoft has written an article about this bug, explaining the reasons for
  # treating 1900 as a leap year. This bug has been promoted into a requirement in the Ecma Office
  # Open XML (OOXML) specification.
  defp adjust_for_lotus_bug(day) when day > 59, do: day - 1
  defp adjust_for_lotus_bug(day), do: day
end

defmodule DateTimeParser.Serial do
  @moduledoc false

  def parse(string) do
    if String.contains?(string, ".") do
      with {float, _} <- Float.parse(string) do
        {:ok, [serial: float], nil, nil, nil, nil}
      end
    else
      with {integer, _} <- Integer.parse(string) do
        {:ok, [serial: integer], nil, nil, nil, nil}
      end
    end
  end

  def from_tokens(tokens, opts) do
    with {:ok, date_or_datetime} <- from_tokens(tokens[:serial]) do
      assume_time(date_or_datetime, opts[:assume_time])
    end
  end

  def from_tokens(nil), do: :error

  def from_tokens(float) when is_float(float) do
    {serial_date, serial_time} = split_float(float)
    erl_time = time_from_serial(serial_time)
    erl_date = date_from_serial(serial_date)
    NaiveDateTime.from_erl({erl_date, erl_time})
  end

  def from_tokens(integer) when is_integer(integer) do
    erl_date = date_from_serial(integer)
    Date.from_erl(erl_date)
  end

  defp assume_time(datetime, true), do: assume_time(datetime, ~T[00:00:00])
  defp assume_time(%Date{} = date, %Time{} = time) do
    NaiveDateTime.new(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      time.second,
      time.microsecond
    )
  end
  defp assume_time(datetime, _), do: {:ok, datetime}

  def time_from_serial(0.0), do: {0, 0, 0}

  def time_from_serial(serial_time) do
    {hours, min_fraction} = split_float(serial_time * 24)
    {minutes, sec_fraction} = split_float(min_fraction * 60)
    {seconds, _microseconds} = split_float(sec_fraction * 60)

    {hours, minutes, seconds}
  end

  def date_from_serial(nil), do: :error

  def date_from_serial(serial_date) do
    {1899, 12, 31}
    |> :calendar.date_to_gregorian_days()
    |> Kernel.+(serial_date)
    |> adjust_for_lotus_bug
    |> :calendar.gregorian_days_to_date()
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

defmodule DateTimeParser.Combinators.Time do
  @moduledoc false

  import DateTimeParser.Combinators.TimeZone
  import NimbleParsec

  @hour_num ~w(00 01 02 03 04 05 06 07 08 09) ++ Enum.map(23..0, &to_string/1)
  @second_minute_num ~w(00 01 02 03 04 05 06 07 08 09) ++ Enum.map(59..0, &to_string/1)
  @am_pm ~w(am a.m a.m. a_m pm p.m p.m. p_m a p)
  @time_separator ":"

  def to_integer(value) when is_binary(value), do: String.to_integer(value)

  def hour do
    @hour_num
    |> Enum.map(&string/1)
    |> choice()
    |> map(:to_integer)
    |> unwrap_and_tag(:hour)
    |> label("numeric hour from 00-23")
  end

  def microsecond do
    [?0..?9]
    |> ascii_char()
    |> times(min: 1, max: 24)
    |> tag(:microsecond)
    |> label("numeric subsecond up to 24 digits")
  end

  def second_or_minute do
    @second_minute_num
    |> Enum.map(&string/1)
    |> choice()
    |> map(:to_integer)
  end

  def second do
    second_or_minute()
    |> unwrap_and_tag(:second)
    |> label("numeric second from 00-59")
    |> concat("." |> string() |> ignore() |> optional())
    |> concat(microsecond() |> optional())
  end

  def minute do
    second_or_minute()
    |> unwrap_and_tag(:minute)
    |> label("numeric minute from 00-59")
  end

  def hour_minute do
    hour()
    |> concat(time_separator() |> optional() |> ignore())
    |> concat(minute())
  end

  def hour_minute_second do
    hour_minute()
    |> concat(time_separator() |> optional() |> ignore())
    |> concat(second())
  end

  def am_pm do
    @am_pm
    |> Enum.map(&string/1)
    |> choice()
    |> lookahead_not(second_letter_of_timezone_abbreviation())
    |> unwrap_and_tag(:am_pm)
    |> label("am or pm")
  end

  def time do
    choice([
      hour_minute_second(),
      hour_minute()
    ])
    |> concat(space_separator() |> optional() |> ignore())
    |> concat(am_pm() |> optional())
  end

  defp space_separator, do: string(" ")

  defp time_separator, do: string(@time_separator)
end

defmodule DateTimeParser do
  @moduledoc """
  Documentation for DateTimeParser.
  """

  # TODO:
  #   - offset parsing
  #   - day-month-year isn't right with month-day-year. Usually it's day-wordmonth-year.
  #   - Need to put year-month-day as priority (but 2-digit year screws it up)
  #   - Year parsing puts "18" as "0018"

  import NimbleParsec

  # @days ~w(sunday monday tuesday wednesday thursday friday saturday)
  @days_num ~w(01 02 03 04 05 06 07 08 09) ++ ((1..31) |> Enum.map(&to_string/1) |> Enum.reverse())
  # @days_abbr ~w(sun mon tue tues wed thu fri sat)
  @months ~w(january february march april may june july august september october november december)
  @months_abbr ~w(jan feb mar apr may jun jul aug sep oct nov dec)
  @month_map %{"january" => 1, "february" => 2, "march" => 3, "april" => 4, "may" => 5, "june" => 6,
    "july" => 7, "august" => 8, "september" => 9, "october" => 10, "november" => 11, "december"=>
    12, "jan" => 1, "feb" => 2, "mar" => 3, "apr" => 4, "jun" => 6, "jul" => 7, "aug" =>
    8, "sep" => 9, "oct" => 10, "nov" => 11, "dec"=> 12}
  @months_num ~w(01 02 03 04 05 06 07 08 09) ++ ((12..1) |> Enum.map(&to_string/1))
  @hour_num ~w(00 01 02 03 04 05 06 07 08 09) ++ ((24..1) |> Enum.map(&to_string/1))
  @minute_num ~w(00 01 02 03 04 05 06 07 08 09) ++ ((59..1) |> Enum.map(&to_string/1))
  @second_num ~w(00 01 02 03 04 05 06 07 08 09) ++ ((59..1) |> Enum.map(&to_string/1))
  @am_pm ~w(am a.m a.m. a_m a pm p.m p.m p_m p)
  @date_seperator ~w(, . : / - \s)

  @utc ~w(utc gmt z)
  @est ~w(est edt et eastern)
  @pst ~w(pst pdt pt pacific)
  @cst ~w(cst cdt ct central)
  @mst ~w(mst mdt mt mountain)
  @akst ~w(akst akdt akt alaska)
  @hast ~w(hast hadt hat hst hawaii)
  @timezone_abbreviations @utc ++ @est ++ @pst ++ @cst ++ @mst ++ @akst ++ @hast

  defp vocal_month_to_numeric_month(val), do: Map.get(@month_map, String.downcase(val))
  defp to_integer({token, value}), do: {token, String.to_integer(value)}

  year =
    [integer(4), integer(3), integer(2)]
    |> choice()
    |> unwrap_and_tag(:year)
    |> label("2 or 4 digit year")

  vocal_month =
    (@months ++ @months_abbr)
    |> Enum.map(&([String.capitalize(&1), String.upcase(&1), String.downcase(&1)]))
    |> List.flatten()
    |> Enum.map(&string/1)
    |> choice()
    |> map(:vocal_month_to_numeric_month)
    |> label("word month either fully spelled or 3-letter abbreviation")
    |> unwrap_and_tag(:month)

  numeric_month =
    @months_num
    |> Enum.map(&string/1)
    |> choice()
    |> unwrap_and_tag(:month)
    |> map(:to_integer)
    |> label("numeric month from 00-12")

  day_of_month =
    @days_num
    |> Enum.map(&string/1)
    |> choice()
    |> unwrap_and_tag(:day)
    |> map(:to_integer)
    |> label("numeric day from 00-31")

  date_seperator =
    @date_seperator
    |> Enum.map(&string/1)
    |> choice()
    |> label("date seperator")

  hour =
    @hour_num
    |> Enum.map(&string/1)
    |> choice()
    |> unwrap_and_tag(:hour)
    |> map(:to_integer)
    |> label("numeric hour from 00-24")

  microsecond =
    [integer(6), integer(5), integer(4), integer(3), integer(2), integer(1)]
    |> choice()
    |> unwrap_and_tag(:microsecond)
    |> label("numeric microsecond up to 6 digits")

  second =
    @second_num
    |> Enum.map(&string/1)
    |> choice()
    |> unwrap_and_tag(:second)
    |> map(:to_integer)
    |> label("numeric second from 00-59")
    |> concat("." |> string() |> ignore() |> optional())
    |> concat(microsecond |> optional())

  minute =
    @minute_num
    |> Enum.map(&string/1)
    |> choice()
    |> unwrap_and_tag(:minute)
    |> map(:to_integer)
    |> label("numeric minute from 00-59")

  hour_minute =
    hour
    |> concat(date_seperator |> optional())
    |> concat(minute)

  hour_minute_second =
    hour_minute
    |> concat(date_seperator |> optional())
    |> concat(second |> optional())

  time_zone_offset =
    ["+", "-"]
    |> Enum.map(&string/1)
    |> choice()
    |> concat(integer(4))
    |> tag(:utc_offset)

  am_pm =
    @am_pm
    |> Enum.map(&([String.upcase(&1), String.downcase(&1)]))
    |> List.flatten()
    |> Enum.map(&string/1)
    |> choice()
    |> label("am or pm")
    |> unwrap_and_tag(:am_pm)

  timezone_plus_offset =
    @utc
    |> Enum.map(&string/1)
    |> choice()
    |> label("timezone with offset")
    |> lookahead(time_zone_offset)

  timezone_abbreviation =
    @timezone_abbreviations
    |> Enum.map(&([String.capitalize(&1), String.upcase(&1), String.downcase(&1)]))
    |> List.flatten()
    |> Enum.map(&string/1)
    |> choice()
    |> label("timezone abbreviation")
    |> unwrap_and_tag(:zone_abbr)

  month = choice([
    numeric_month,
    vocal_month
  ])

  month_day =
    month
    |> concat(date_seperator |> optional())
    |> concat(day_of_month)

  day_month =
    day_of_month
    |> concat(date_seperator |> optional())
    |> concat(month)

  year_month_day =
    year
    |> concat(date_seperator |> optional())
    |> concat(month_day)

  month_day_year =
    month_day
    |> concat(date_seperator |> optional())
    |> concat(year)

  day_month_year =
    day_month
    |> concat(date_seperator |> optional())
    |> concat(year)

  timezone =
    concat(
      " " |> string() |> optional() |> ignore(),
      choice([
        timezone_plus_offset,
        timezone_abbreviation
      ])
    )

  time_seperator =
    choice([
      "T" |> string(),
      " " |> string(),
      "-" |> string()
    ])

  time =
    hour_minute_second
    |> concat(optional(am_pm))
    |> concat(optional(timezone))

  formal_date = choice([
    day_month_year,
    month_day_year,
    year_month_day,
    day_month,
    month_day
  ])

  formal_date_time =
    formal_date
    |> concat(time_seperator)
    |> concat(optional(time))

  defparsec :do_parse, choice([
    formal_date_time,
    formal_date
  ])

  def parse(string) do
    {:ok, tokens, _, _, _, _} =
      string
      |> String.trim()
      |> String.replace(~r/[[:space:]]+/, " ")
      |> String.replace(" - ", " ")
      |> do_parse()
    IO.inspect tokens, label: "TOKENS"
    if has_timezone?(tokens) do
      to_datetime(tokens)
    else
      to_naive_datetime(tokens)
    end
  end

  defp has_timezone?(tokens) do
    Enum.any?([
      format_token(tokens, :zone_abbr),
      format_token(tokens, :utc_offset)
    ])
  end

  defp to_naive_datetime(tokens) do
    Map.merge(
      NaiveDateTime.utc_now(),
      clean(%{
        year: format_token(tokens, :year),
        month: format_token(tokens, :month),
        day: format_token(tokens, :day),
        hour: format_token(tokens, :hour) || 0,
        minute: format_token(tokens, :minute) || 0,
        second: format_token(tokens, :second) || 0,
        microsecond: format_token(tokens, :microsecond) || {0, 0}
      })
    )
  end

  defp to_datetime(tokens) do
    Map.merge(
      DateTime.utc_now(),
      clean(%{
        year: format_token(tokens, :year),
        month: format_token(tokens, :month),
        day: format_token(tokens, :day),
        hour: format_token(tokens, :hour) || 0,
        minute: format_token(tokens, :minute) || 0,
        second: format_token(tokens, :second) || 0,
        microsecond: format_token(tokens, :microsecond) || {0, 0}
      })
    )
  end

  defp clean(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp format_token(tokens, :hour) do
    case tokens |> find_token(:hour) do
      {:hour, hour} ->
         if tokens |> find_token(:am_pm) |> format == "PM" do
           hour + 12
         else
           hour
         end
      _ ->
        nil
    end
  end
  defp format_token(tokens, token) do
    tokens |> find_token(token) |> format()
  end

  defp find_token(tokens, find_me) do
    Enum.find(tokens, fn
      {token, _} -> token == find_me
      _ -> false
    end)
  end

  defp format({:microsecond, value}), do: {value, value |> Integer.digits() |> length()}
  defp format({:zone_abbr, value}), do: String.upcase(value)
  defp format({:am_pm, value}), do: String.upcase(value)
  defp format({:am_pm, value}), do: String.upcase(value)
  defp format({_, value}) when is_integer(value), do: value
  defp format({_, value}), do: String.to_integer(value)
  defp format(_), do: nil
end

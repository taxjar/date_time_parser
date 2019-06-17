defmodule DateTimeParser do
  @moduledoc """
  Documentation for DateTimeParser.
  """

  # TODO:
  #   - Scenario when d-m-yyyy should win instead of y-m-d
  #   - Scenario when d-m-yy when y > 31 should win instead of y-m-d
  #   - Natural language.
  #   - Ignore/parse vocal days, like Sunday, January 1, 2013

  import NimbleParsec

  # @days ~w(sunday monday tuesday wednesday thursday friday saturday)
  # @days_abbr ~w(sun mon tue tues wed wednes thurs thur fri sat)
  @days_num ~w(01 02 03 04 05 06 07 08 09) ++ ((1..31) |> Enum.map(&to_string/1) |> Enum.reverse())
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
  @date_seperator ~w(, . : / -) ++ [" "]

  @utc ~w(utc gmt z)
  @eastern ~w(est edt et eastern)
  @pacific ~w(pst pdt pt pacific)
  @central ~w(cst cdt ct central)
  @mountain ~w(mst mdt mt mountain)
  @alaska ~w(akst akdt akt alaska)
  @hawaii ~w(hast hadt hat hst hawaii)
  @timezone_abbreviations @utc ++ @eastern ++ @pacific ++ @central ++ @mountain ++ @alaska ++ @hawaii

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
    |> unwrap_and_tag(:month)
    |> label("word month either fully spelled or 3-letter abbreviation")

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
    |> ignore()
    |> label("date seperator")

  hour =
    @hour_num
    |> Enum.map(&string/1)
    |> choice()
    |> unwrap_and_tag(:hour)
    |> map(:to_integer)
    |> label("numeric hour from 00-24")

  microsecond =
    [?0..?9]
    |> ascii_char()
    |> times(min: 1, max: 6)
    |> tag(:microsecond)
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

  offset =
    ["+", "-"]
    |> Enum.map(&string/1)
    |> choice()
    |> concat([?0..?9] |> ascii_char() |> times(4))
    |> tag(:utc_offset)
    |> label("offset with +/- and 4 digits")

  am_pm =
    @am_pm
    |> Enum.map(&([String.upcase(&1), String.downcase(&1)]))
    |> List.flatten()
    |> Enum.map(&string/1)
    |> choice()
    |> label("am or pm")
    |> unwrap_and_tag(:am_pm)

  utc =
    @utc
    |> Enum.map(&([String.capitalize(&1), String.upcase(&1), String.downcase(&1)]))
    |> List.flatten()
    |> Enum.map(&string/1)
    |> choice()
    |> replace("UTC")
    |> label("timezone with offset")
    |> unwrap_and_tag(:zone_abbr)

  utc_plus_offset =
    concat(utc, offset)

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

  day_long_month_year =
    day_of_month
    |> concat(date_seperator |> optional())
    |> concat(vocal_month)
    |> concat(date_seperator |> optional())
    |> concat(year)

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
    choice([
      utc_plus_offset,
      utc,
      offset,
      timezone_abbreviation
    ])

  time_seperator =
    [
      "T" |> string(),
      " " |> string(),
      "-" |> string()
    ]
    |> choice()
    |> ignore()

  space_seperator =
    string(" ")
    |> optional()
    |> ignore()

  time =
    hour_minute_second
    |> concat(optional(space_seperator))
    |> concat(optional(am_pm))
    |> concat(optional(space_seperator))
    |> concat(optional(timezone))

  formal_date = choice([
    day_long_month_year,
    year_month_day,
    day_month_year,
    month_day_year,
    day_month,
    month_day
  ])

  formal_date_time =
    formal_date
    |> concat(time_seperator)
    |> concat(optional(time))

  defparsecp :do_parse_time, time

  defparsecp :do_parse, choice([
    formal_date_time,
    formal_date
  ])

  def parse(string, opts \\ [])
  def parse(string, opts) when is_binary(string) do
    with {:ok, tokens, _, _, _, _} <- string |> clean() |> do_parse() do
      IO.inspect tokens, label: "TOKENS"
      {:ok,
        tokens
        |> to_naive_datetime()
        |> to_datetime(tokens)
        |> maybe_convert_to_utc(opts)
      }
    end
  end
  def parse(nil, _opts), do: {:error, "Could not parse nil"}
  def parse(value, _opts), do: {:error, "Could not parse #{value}"}

  def parse_time(string) do
    {:ok, tokens, _, _, _, _} = string |> clean |> do_parse_time()
    IO.inspect tokens, label: "TOKENS"
    to_time(tokens)
  end

  defp to_time(tokens) do
    Time.new(
      format_token(tokens, :hour) || 0,
      format_token(tokens, :minute) || 0,
      format_token(tokens, :second) || 0,
      format_token(tokens, :microsecond) || {0, 0}
    )
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

  defp to_datetime(naive_datetime, tokens) do
    with zone <- format_token(tokens, :zone_abbr),
         offset <- format_token(tokens, :utc_offset),
         true <- Enum.any?([zone, offset]),
         %{} = timezone_info <- Timex.Timezone.get(zone || offset) do
      naive_datetime
      |> DateTime.from_naive!("Etc/UTC")
      |> Map.merge(%{
        std_offset: timezone_info.offset_std,
        utc_offset: timezone_info.offset_utc,
        zone_abbr: timezone_info.abbreviation,
        time_zone: timezone_info.full_name
      })
    else
      _ -> naive_datetime
    end
  end

  defp maybe_convert_to_utc(%NaiveDateTime{} = naive_datetime, _opts), do: naive_datetime
  defp maybe_convert_to_utc(%DateTime{} = datetime, opts) do
    case Keyword.get(opts, :convert_to_utc, true) do
      true -> Timex.Timezone.convert(datetime, "Etc/UTC")
      _ -> datetime
    end
  end

  defp clean(string) when is_binary(string) do
    string
    |> String.trim()
    |> String.replace(~r/[[:space:]]+/, " ")
    |> String.replace(~r/\ -\ /, "-")
    |> String.replace(~r/\"|'|,|=|\\/, "")
  end
  defp clean(%{} = map) do
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
  defp format_token(tokens, :year) do
    case tokens |> find_token(:year) |> format() do
      nil ->
        nil
      year ->
        year
        |> Integer.digits()
        |> to_4_year
        |> Integer.undigits()
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

  # If the parsed two-digit year is 00 to 49, then
  #  - If the last two digits of the current year are 00 to 49, then the returned year has the same
  #    first two digits as the current year.
  #  - If the last two digits of the current year are 50 to 99, then the first 2 digits of the
  #    returned year are 1 greater than the first 2 digits of the current year.
  # If the parsed two-digit year is 50 to 99, then
  #  - If the last two digits of the current year are 00 to 49, then the first 2 digits of the
  #    returned year are 1 less than the first 2 digits of the current year.
  #  - If the last two digits of the current year are 50 to 99, then the returned year has the same
  #    first two digits as the current year.
  defp to_4_year(digits) when length(digits) == 4, do: digits
  defp to_4_year(digits) when length(digits) == 3 do
    [current_millenia | _rest] =
      DateTime.utc_now()
      |> Map.get(:year)
      |> Integer.digits()

    [current_millenia | digits]
  end
  defp to_4_year(digits) when length(digits) == 2 do
    [current_millenia, current_century, current_decade, current_year] =
      DateTime.utc_now()
      |> Map.get(:year)
      |> Integer.digits()

    current_2yr = Integer.undigits([current_decade, current_year])
    parsed_2yr = Integer.undigits(digits)
    cond do
      parsed_2yr < 50 && current_2yr < 50  ->
        [current_millenia, current_century | digits]

      parsed_2yr < 50 && current_2yr >= 50 ->
        [parsed_millenia, parsed_century] =
          [current_millenia, current_century]
          |> Integer.undigits()
          |> Kernel.+(1)
          |> Integer.digits()
        [parsed_millenia, parsed_century | digits]

      parsed_2yr >= 50 && current_2yr < 50  ->
        [parsed_millenia, parsed_century] =
          [current_millenia, current_century]
          |> Integer.undigits()
          |> Kernel.-(1)
          |> Integer.digits()
        [parsed_millenia, parsed_century | digits]

      parsed_2yr >= 50 && current_2yr >= 50 ->
        [current_millenia, current_century | digits]
    end
  end
  defp to_4_year(digits) when length(digits) == 1, do: []

  defp format({:microsecond, value}) do
    {
      value |> to_string |> String.to_integer,
      value |> to_string |> String.graphemes() |> length()
    }
  end
  defp format({:zone_abbr, value}), do: String.upcase(value)
  defp format({:utc_offset, offset}), do: to_string(offset)
  defp format({:am_pm, value}), do: String.upcase(value)
  defp format({_, value}) when is_integer(value), do: value
  defp format({_, value}), do: String.to_integer(value)
  defp format(_), do: nil
end

defmodule DateTimeParser do
  @moduledoc """
  Documentation for DateTimeParser.
  """

  # TODO:
  #   - Natural language.

  import NimbleParsec

  @days_map %{
    "sun" => "Sunday", "mon" => "Monday", "tue" => "Tuesday", "tues" => "Tuesday", "wed" =>
    "Wednesday", "thurs" => "Thursday", "thur" => "Thursday", "thu" => "Thursday", "fri" =>
    "Friday", "sat" => "Saturday"
  }
  @days_num ~w(01 02 03 04 05 06 07 08 09) ++ Enum.map(31..1, &to_string/1)
  @months_map %{
    "january" => 1, "february" => 2, "march" => 3, "april" => 4, "may" => 5, "june" => 6, "july" =>
    7, "august" => 8, "september" => 9, "october" => 10, "november" => 11, "december"=> 12, "jan" =>
    1, "feb" => 2, "mar" => 3, "apr" => 4, "jun" => 6, "jul" => 7, "aug" => 8, "sep" => 9, "sept" =>
    9, "oct" => 10, "nov" => 11, "dec"=> 12
  }
  @months_num ~w(01 02 03 04 05 06 07 08 09) ++  Enum.map(12..0, &to_string/1)
  @hour_num ~w(00 01 02 03 04 05 06 07 08 09) ++ Enum.map(24..0, &to_string/1)
  @minute_num ~w(00 01 02 03 04 05 06 07 08 09) ++ Enum.map(59..0, &to_string/1)
  @second_num ~w(00 01 02 03 04 05 06 07 08 09) ++ Enum.map(59..0, &to_string/1)
  @am_pm ~w(am a.m a.m. a_m pm p.m p.m p_m a p)
  @date_separator ~w(, . : / -) ++ [" "]
  @datetime_separator ~w(t - +) ++ [" "]
  @time_separator ":"

  @utc ~w(utc gmt z)
  @eastern ~w(est edt et eastern)
  @pacific ~w(pst pdt pt pacific)
  @central ~w(cst cdt ct central)
  @mountain ~w(mst mdt mt mountain)
  @alaska ~w(akst akdt akt alaska)
  @hawaii ~w(hast hadt hat hst hawaii)
  @timezone_abbreviations @utc ++ @eastern ++ @pacific ++ @central ++ @mountain ++ @alaska ++
    @hawaii

  defp vocal_month_to_numeric_month(val), do: Map.get(@months_map, val)
  defp to_integer({token, value}), do: {token, String.to_integer(value)}

  time_separator = string(@time_separator)

  datetime_separator =
    @datetime_separator
    |> Enum.map(&string/1)
    |> choice()

  space_separator = string(" ")

  year =
    [?0..?9]
    |> ascii_char()
    |> times(max: 4, min: 2)
    |> tag(:year)
    |> label("2 or 4 digit year")

  year4 =
    [?0..?9]
    |> ascii_char()
    |> times(4)
    |> tag(:year)

  vocal_month =
    @months_map
    |> Map.keys()
    |> Enum.sort_by(&byte_size/1)
    |> Enum.reverse()
    |> Enum.map(&string/1)
    |> choice()
    |> concat(string(".") |> optional() |> ignore())
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

  date_separator =
    @date_separator
    |> Enum.map(&string/1)
    |> choice()
    |> ignore()
    |> label("date separator")

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
    |> concat(time_separator |> optional() |> ignore())
    |> concat(minute |> optional())

  hour_minute_second =
    hour_minute
    |> concat(time_separator |> optional() |> ignore())
    |> concat(second |> optional())

  offset =
    ["+", "-"]
    |> Enum.map(&string/1)
    |> choice()
    |> concat([?0..?9] |> ascii_char() |> times(min: 1, max: 2))
    |> concat(time_separator |> optional() |> ignore())
    |> concat([?0..?9] |> ascii_char() |> times(2) |> optional())
    |> tag(:utc_offset)
    |> label("offset with +/- and 4 digits")

  utc =
    @utc
    |> Enum.map(&string/1)
    |> choice()
    |> replace("UTC")
    |> label("timezone with offset")
    |> unwrap_and_tag(:zone_abbr)

  utc_plus_offset =
    concat(utc, offset)

  timezone_abbreviation =
    @timezone_abbreviations
    |> Enum.map(&string/1)
    |> choice()
    |> label("timezone abbreviation")
    |> unwrap_and_tag(:zone_abbr)

  second_letter_of_timezone_abbreviation =
    @timezone_abbreviations
    |> Enum.map(fn abbr -> abbr |> String.codepoints() |> Enum.at(1) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn char -> <<codepoint::utf8>> = char; codepoint end)
    |> ascii_char

  am_pm =
    @am_pm
    |> Enum.map(&string/1)
    |> choice()
    |> lookahead_not(second_letter_of_timezone_abbreviation)
    |> label("am or pm")
    |> unwrap_and_tag(:am_pm)

  month = choice([
    numeric_month,
    vocal_month
  ])

  month_day =
    month
    |> concat(date_separator |> optional())
    |> concat(day_of_month)

  day_month =
    day_of_month
    |> concat(date_separator |> optional())
    |> concat(month)

  day_long_month_year =
    day_of_month
    |> concat(date_separator |> optional())
    |> concat(vocal_month)
    |> concat(date_separator |> optional())
    |> concat(year)

  year_month_day =
    year
    |> concat(date_separator |> optional())
    |> concat(month_day)

  month_day_year =
    month_day
    |> concat(date_separator |> optional())
    |> concat(year)

  day_month_year4 =
    day_month
    |> concat(date_separator)
    |> concat(year4)

  day_month_year =
    day_month
    |> concat(date_separator |> optional())
    |> concat(year)

  timezone =
    choice([
      utc_plus_offset,
      utc,
      offset,
      timezone_abbreviation
    ])

  time =
    hour_minute_second
    |> concat(space_separator |> optional() |> ignore())
    |> concat(am_pm |> optional())

  formal_date = choice([
    day_long_month_year,
    day_month_year4,
    year_month_day,
    day_month_year,
    month_day_year,
    day_month,
    month_day
  ])

  us_date = choice([
    day_long_month_year,
    month_day_year,
    day_month_year,
    year_month_day,
    day_month,
    month_day
  ])

  vocal_month_day_time_year =
    vocal_month
    |> concat(space_separator |> ignore())
    |> concat(day_of_month)
    |> concat(space_separator |> ignore())
    |> concat(time)
    |> concat(space_separator |> optional() |> ignore())
    |> concat(year4)

  formal_date_time =
    formal_date
    |> concat(datetime_separator |> optional() |> ignore())
    |> concat(time |> optional())
    |> concat(space_separator |> optional() |> ignore())
    |> concat(timezone |> optional())

  us_date_time =
    us_date
    |> concat(datetime_separator |> optional() |> ignore())
    |> concat(time |> optional())
    |> concat(space_separator |> optional() |> ignore())
    |> concat(timezone |> optional())

  vocal_days_long =
    @days_map
    |> Map.values()
    |> Enum.map(&String.downcase/1)
    |> Enum.sort_by(&byte_size/1)
    |> Enum.reverse()
    |> Enum.map(&string/1)

  vocal_days_short =
    @days_map
    |> Map.keys()
    |> Enum.map(&String.downcase/1)
    |> Enum.sort_by(&byte_size/1)
    |> Enum.reverse()
    |> Enum.map(&string/1)

  vocal_day =
    (vocal_days_long ++ vocal_days_short)
    |> choice()
    |> unwrap_and_tag(:vocal_day)
    |> label("vocal day spelled out")
    |> concat(
      choice([
        string(" "),
        concat(string(","), string(" "))
      ])
      |> optional()
      |> ignore()
    )

  defparsecp :do_parse_time, time

  defparsecp :do_parse,
    vocal_day
    |> optional()
    |> choice([
      vocal_month_day_time_year,
      formal_date_time,
      formal_date
    ])

  defparsecp :do_us_parse,
    vocal_day
    |> optional()
    |> choice([
      vocal_month_day_time_year,
      us_date_time,
      us_date
    ])

  def parse(string, opts \\ [])
  def parse(string, opts) when is_binary(string) do
    parser = if String.contains?(string, "/"), do: &do_us_parse/1, else: &do_parse/1
    with {:ok, tokens, _, _, _, _} <- string |> clean() |> parser.() do
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
         %{} = timezone_info <- Timex.Timezone.get(offset || zone) do
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
    |> String.replace(" @ ", "T")
    |> String.replace(~r/[[:space:]]+/, " ")
    |> String.replace(" - ", "-")
    |> String.replace("//", "/")
    |> String.replace(~r/\"|'|,|=|\\/, "")
    |> String.downcase()
  end
  defp clean(%{} = map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp format_token(tokens, :hour) do
    case tokens |> find_token(:hour) do
      {:hour, hour} ->
         if tokens |> find_token(:am_pm) |> format == "PM" && hour <= 12 do
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
        year |> to_4_year() |> String.to_integer()
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
  defp to_4_year(parsed_year) when byte_size(parsed_year) == 4, do: parsed_year
  defp to_4_year(parsed_3yr) when byte_size(parsed_3yr) == 3 do
    [current_millenia | _rest] =
      DateTime.utc_now()
      |> Map.get(:year)
      |> Integer.digits()

    "#{current_millenia}#{parsed_3yr}"
  end
  defp to_4_year(parsed_2yr) when byte_size(parsed_2yr) == 2 do
    [current_millenia, current_century, current_decade, current_year] =
      DateTime.utc_now()
      |> Map.get(:year)
      |> Integer.digits()
    parsed_2yr = String.to_integer(parsed_2yr)
    current_2yr = String.to_integer("#{current_decade}#{current_year}")

    cond do
      parsed_2yr < 50 && current_2yr < 50  ->
        "#{current_millenia}#{current_century}#{parsed_2yr}"

      parsed_2yr < 50 && current_2yr >= 50 ->
        [_parsed_millenia, parsed_century] =
          [current_millenia, current_century]
          |> Integer.undigits()
          |> Kernel.+(1)
          |> Integer.digits()
        "#{current_millenia}#{parsed_century}#{parsed_2yr}"

      parsed_2yr >= 50 && current_2yr < 50  ->
        [parsed_millenia, parsed_century] =
          [current_millenia, current_century]
          |> Integer.undigits()
          |> Kernel.-(1)
          |> Integer.digits()
        "#{parsed_millenia}#{parsed_century}#{parsed_2yr}"

      parsed_2yr >= 50 && current_2yr >= 50 ->
        "#{current_millenia}#{current_century}#{parsed_2yr}"
    end
  end
  defp to_4_year(parsed_year) when byte_size(parsed_year) == 1, do: []

  defp format({:microsecond, value}) do
    {
      value |> to_string |> String.to_integer,
      value |> to_string |> String.graphemes() |> length()
    }
  end
  defp format({:zone_abbr, value}), do: String.upcase(value)
  defp format({:utc_offset, offset}), do: to_string(offset)
  defp format({:year, value}), do: to_string(value)
  defp format({:am_pm, value}), do: String.upcase(value)
  defp format({_, value}) when is_integer(value), do: value
  defp format({_, value}), do: String.to_integer(value)
  defp format(_), do: nil
end

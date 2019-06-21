defmodule DateTimeParser.Combinators do
  @moduledoc false

  import NimbleParsec

  @days_map %{
    "sun" => "Sunday",
    "mon" => "Monday",
    "tue" => "Tuesday",
    "tues" => "Tuesday",
    "wed" => "Wednesday",
    "thurs" => "Thursday",
    "thur" => "Thursday",
    "thu" => "Thursday",
    "fri" => "Friday",
    "sat" => "Saturday"
  }
  @months_map %{
    "january" => 1,
    "february" => 2,
    "march" => 3,
    "april" => 4,
    "may" => 5,
    "june" => 6,
    "july" => 7,
    "august" => 8,
    "september" => 9,
    "october" => 10,
    "november" => 11,
    "december" => 12,
    "jan" => 1,
    "feb" => 2,
    "mar" => 3,
    "apr" => 4,
    "jun" => 6,
    "jul" => 7,
    "aug" => 8,
    "sept" => 9,
    "sep" => 9,
    "oct" => 10,
    "nov" => 11,
    "dec" => 12
  }
  @hour_num ~w(00 01 02 03 04 05 06 07 08 09) ++ Enum.map(23..0, &to_string/1)
  @second_minute_num ~w(00 01 02 03 04 05 06 07 08 09) ++ Enum.map(59..0, &to_string/1)
  @am_pm ~w(am a.m a.m. a_m pm p.m p.m p_m a p)
  @date_separator ~w(, . : / -) ++ [" "]
  @datetime_separator ~w(t - +) ++ [" "]
  @time_separator ":"

  @utc ~w(utc gmt z)
  @eastern ~w(eastern est edt et)
  @pacific ~w(pacific pst pdt pt)
  @central ~w(central cst cdt ct)
  @mountain ~w(mountain mst mdt mt)
  @alaska ~w(alaska akst akdt akt)
  @hawaii ~w(hawaii hast hadt hat hst)
  @timezone_abbreviations @utc ++
                            @eastern ++
                            @pacific ++
                            @central ++
                            @mountain ++
                            @alaska ++
                            @hawaii

  def vocal_month_to_numeric_month(value), do: Map.get(@months_map, value)
  def to_integer(value) when is_binary(value), do: String.to_integer(value)

  def time_separator do
    string(@time_separator)
  end

  def datetime_separator do
    @datetime_separator
    |> Enum.map(&string/1)
    |> choice()
  end

  def space_separator do
    string(" ")
  end

  def year4 do
    [?0..?9]
    |> ascii_char()
    |> times(4)
    |> tag(:year)
    |> label("4 digit year")
  end

  def year do
    [?0..?9]
    |> ascii_char()
    |> times(max: 4, min: 2)
    |> tag(:year)
    |> label("2 or 4 digit year")
  end

  def vocal_month do
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
  end

  def numeric_month do
    choice([
      numeric_month2(),
      numeric_month1()
    ])
    |> map(:to_integer)
    |> unwrap_and_tag(:month)
    |> label("numeric month from 01-12")
  end

  def numeric_month2 do
    ~w(01 02 03 04 05 06 07 08 09 10 11 12)
    |> Enum.map(&string/1)
    |> choice()
  end

  def numeric_month1 do
    1..9
    |> Enum.map(&to_string/1)
    |> Enum.map(&string/1)
    |> choice()
    |> lookahead_not(integer(min: 1))
  end

  def day do
    choice([
      day2(),
      day1()
    ])
    |> map(:to_integer)
    |> unwrap_and_tag(:day)
    |> label("numeric day from 01-31")
  end

  def day2 do
    (~w(01 02 03 04 05 06 07 08 09) ++ Enum.map(10..31, &to_string/1))
    |> Enum.map(&string/1)
    |> choice()
  end

  def day1 do
    1..9
    |> Enum.map(&to_string/1)
    |> Enum.map(&string/1)
    |> choice()
    |> lookahead_not(integer(min: 1))
  end

  def date_separator do
    @date_separator
    |> Enum.map(&string/1)
    |> choice()
    |> ignore()
    |> label("date separator")
  end

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
    |> times(min: 1, max: 6)
    |> tag(:microsecond)
    |> label("numeric microsecond up to 6 digits")
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

  def offset do
    ["+", "-"]
    |> Enum.map(&string/1)
    |> choice()
    |> concat([?0..?9] |> ascii_char() |> times(min: 1, max: 2))
    |> concat(time_separator() |> optional() |> ignore())
    |> concat([?0..?9] |> ascii_char() |> times(2) |> optional())
    |> tag(:utc_offset)
    |> label("offset with +/- and 4 digits")
  end

  def utc do
    @utc
    |> Enum.map(&string/1)
    |> choice()
    |> replace("UTC")
    |> unwrap_and_tag(:zone_abbr)
    |> label("timezone with offset")
  end

  def utc_plus_offset, do: concat(utc(), offset())

  def timezone_abbreviation do
    @timezone_abbreviations
    |> Enum.map(&string/1)
    |> choice()
    |> unwrap_and_tag(:zone_abbr)
    |> label("timezone abbreviation")
  end

  def second_letter_of_timezone_abbreviation do
    @timezone_abbreviations
    |> Enum.map(fn abbr -> abbr |> String.codepoints() |> Enum.at(1) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn char ->
      <<codepoint::utf8>> = char
      codepoint
    end)
    |> ascii_char
  end

  def am_pm do
    @am_pm
    |> Enum.map(&string/1)
    |> choice()
    |> lookahead_not(second_letter_of_timezone_abbreviation())
    |> unwrap_and_tag(:am_pm)
    |> label("am or pm")
  end

  def month do
    choice([
      numeric_month(),
      vocal_month()
    ])
  end

  def month_day do
    month()
    |> concat(date_separator() |> optional())
    |> concat(day())
  end

  def day_month do
    day()
    |> concat(date_separator() |> optional())
    |> concat(month())
  end

  def day_long_month_year do
    day()
    |> concat(date_separator() |> optional())
    |> concat(vocal_month())
    |> concat(date_separator() |> optional())
    |> concat(year())
  end

  def year_month_day do
    year()
    |> concat(date_separator() |> optional())
    |> concat(month_day())
  end

  def month_day_year do
    month_day()
    |> concat(date_separator() |> optional())
    |> concat(year())
  end

  def day_month_year4 do
    day_month()
    |> concat(date_separator())
    |> concat(year4())
  end

  def day_month_year do
    day_month()
    |> concat(date_separator() |> optional())
    |> concat(year())
  end

  def timezone do
    choice([
      utc_plus_offset(),
      utc(),
      offset(),
      timezone_abbreviation()
    ])
  end

  def time do
    choice([
      hour_minute_second(),
      hour_minute()
    ])
    |> concat(space_separator() |> optional() |> ignore())
    |> concat(am_pm() |> optional())
  end

  def formal_date do
    choice([
      day_long_month_year(),
      day_month_year4(),
      year_month_day(),
      day_month_year(),
      month_day_year(),
      day_month(),
      month_day()
    ])
  end

  def us_date do
    choice([
      day_long_month_year(),
      month_day_year(),
      day_month_year(),
      year_month_day(),
      day_month(),
      month_day()
    ])
  end

  def vocal_month_day_time_year do
    vocal_month()
    |> concat(space_separator() |> ignore())
    |> concat(day())
    |> concat(space_separator() |> ignore())
    |> concat(time())
    |> concat(space_separator() |> optional() |> ignore())
    |> concat(year4())
  end

  def formal_date_time do
    formal_date()
    |> concat(datetime_separator() |> optional() |> ignore())
    |> concat(time() |> optional())
    |> concat(space_separator() |> optional() |> ignore())
    |> concat(timezone() |> optional())
  end

  def us_date_time do
    us_date()
    |> concat(datetime_separator() |> optional() |> ignore())
    |> concat(time())
    |> concat(space_separator() |> optional() |> ignore())
    |> concat(timezone() |> optional())
  end

  def vocal_days_long do
    @days_map
    |> Map.values()
    |> Enum.map(&String.downcase/1)
    |> Enum.sort_by(&byte_size/1)
    |> Enum.reverse()
    |> Enum.map(&string/1)
  end

  def vocal_days_short do
    @days_map
    |> Map.keys()
    |> Enum.map(&String.downcase/1)
    |> Enum.sort_by(&byte_size/1)
    |> Enum.reverse()
    |> Enum.map(&string/1)
  end

  def vocal_day do
    (vocal_days_long() ++ vocal_days_short())
    |> choice()
    |> unwrap_and_tag(:vocal_day)
    |> label("vocal day spelled out")
    |> concat(" " |> string() |> optional() |> ignore())
  end
end

defmodule DateTimeParser.Combinators.Date do
  @moduledoc false

  import NimbleParsec

  @days_map %{
    "sun" => "Sunday",
    "mon" => "Monday",
    "tues" => "Tuesday",
    "tue" => "Tuesday",
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
  @date_separator ~w(, . / -) ++ [" "]

  def vocal_month_to_numeric_month(value), do: Map.get(@months_map, value)
  def to_integer(value) when is_binary(value), do: String.to_integer(value)

  defp space_separator do
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
    |> lookahead_not(integer(1))
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
    |> lookahead_not(integer(1))
  end

  def date_separator do
    @date_separator
    |> Enum.map(&string/1)
    |> choice()
    |> ignore()
    |> label("date separator")
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

  def year4_month_day do
    year4()
    |> concat(date_separator() |> optional())
    |> concat(month_day())
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

  def vocal_days_long do
    @days_map
    |> Map.values()
    |> Enum.uniq()
    |> Enum.map(&String.downcase/1)
    |> Enum.sort_by(&byte_size/1)
    |> Enum.reverse()
    |> Enum.map(&string/1)
  end

  def vocal_days_short do
    @days_map
    |> Map.keys()
    |> Enum.uniq()
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
    |> concat(space_separator() |> optional() |> ignore())
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
      year4_month_day(),
      month_day_year(),
      day_month_year(),
      year_month_day(),
      day_month(),
      month_day()
    ])
  end
end

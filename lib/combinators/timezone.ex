defmodule DateTimeParser.Combinators.TimeZone do
  @moduledoc false

  import NimbleParsec

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
  @time_separator ":"

  defp time_separator do
    string(@time_separator)
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

  def timezone do
    choice([
      utc_plus_offset(),
      utc(),
      offset(),
      timezone_abbreviation()
    ])
  end
end

defmodule DateTimeParser.Combinators.DateTime do
  @moduledoc false

  import DateTimeParser.Combinators.Date
  import DateTimeParser.Combinators.Time
  import DateTimeParser.Combinators.TimeZone
  import NimbleParsec

  @datetime_separator ~w[t - +] ++ [" "]

  def datetime_separator do
    @datetime_separator
    |> Enum.map(&string/1)
    |> choice()
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

  defp space_separator, do: string(" ")
end

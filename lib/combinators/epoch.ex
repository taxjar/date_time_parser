defmodule DateTimeParser.Combinators.Epoch do
  @moduledoc false

  import NimbleParsec

  @separator string(".")

  def unix_epoch_second do
    integer(min: 10, max: 11)
    |> unwrap_and_tag(:unix_epoch)
    |> label("Unix Epoch seconds up to 10 digits")
  end

  def unix_epoch_subsecond do
    integer(min: 1, max: 10)
    |> unwrap_and_tag(:unix_epoch_subsecond)
    |> label("Unix Epoch subseconds up to 10 digits")
  end

  def unix_epoch do
    choice([
      unix_epoch_second()
      |> concat(@separator |> ignore())
      |> concat(unix_epoch_subsecond()),
      unix_epoch_second()
    ])
    |> eos()
  end
end

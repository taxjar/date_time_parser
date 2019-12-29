defmodule DateTimeParser.Parser do
  @moduledoc false
  alias DateTimeParser.Parser

  @epoch_regex ~r|\A(?<seconds>\d{10,11})(?:\.(?<subseconds>\d{1,10}))?\z|
  @serial_regex ~r|\A-?\d{1,5}(?:\.\d{1,10})?\z|
  @default_parsers [:epoch, :serial, :tokenizer]

  def available_parsers, do: @default_parsers

  def get_parser(string, opts) do
    opts = Keyword.merge([tokenizer: get_tokenizer(opts[:context], string)], opts)

    opts
    |> Keyword.get(:parsers, Application.get_env(DateTimeParser, :parsers, @default_parsers))
    |> Enum.find_value({:error, :no_parser}, fn parser ->
      apply(__MODULE__, parser, [string, opts])
    end)
  end

  def epoch(string, _opts) do
    if captures = Regex.named_captures(@epoch_regex, string) do
      {:ok, fn _string -> Parser.Epoch.parse(captures) end}
    end
  end

  def serial(string, _opts) do
    if Regex.match?(@serial_regex, string), do: {:ok, &Parser.Serial.parse/1}
  end

  def tokenizer(_string, opts), do: {:ok, opts[:tokenizer]}

  defp get_tokenizer(:datetime, string) do
    if String.contains?(string, "/") do
      &Parser.DateTime.parse_us/1
    else
      &Parser.DateTime.parse/1
    end
  end

  defp get_tokenizer(:date, string) do
    if String.contains?(string, "/") do
      &Parser.Date.parse_us/1
    else
      &Parser.Date.parse/1
    end
  end

  defp get_tokenizer(:time, _string) do
    &Parser.Time.parse/1
  end
end

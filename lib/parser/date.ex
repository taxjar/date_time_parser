defmodule DateTimeParser.Parser.Date do
  @moduledoc false
  @behaviour DateTimeParser.Parser

  import NimbleParsec
  import DateTimeParser.Combinators.Date
  import DateTimeParser.Formatters, only: [format_token: 2, clean: 1]

  defparsecp(
    :do_parse,
    vocal_day()
    |> optional()
    |> concat(formal_date())
  )

  @impl DateTimeParser.Parser
  def preflight(parser), do: {:ok, parser}

  @impl DateTimeParser.Parser
  def parse(%{string: string} = parser) do
    case do_parse(string) do
      {:ok, tokens, _, _, _, _} -> from_tokens(parser, tokens)
      _ -> {:error, :failed_to_parse}
    end
  end

  def from_tokens(%{context: context, opts: opts}, tokens) do
    parsed_values =
      clean(%{
        year: format_token(tokens, :year),
        month: format_token(tokens, :month),
        day: format_token(tokens, :day)
      })

    with {:ok, date} <-
           for_context(context, parsed_values, Keyword.get(opts, :assume_date, false)),
         {:ok, date} <- validate_day(date) do
      {:ok, date}
    end
  end

  @type dayable :: DateTime.t() | NaiveDateTime.t() | Date.t()

  @doc "Validate either the Date or [Naive]DateTime has a valid day"
  @spec validate_day(dayable) :: {:ok, dayable} | :error
  def validate_day(%{day: day, month: month} = date)
      when month in [1, 3, 5, 7, 8, 10, 12] and day in 1..31,
      do: {:ok, date}

  def validate_day(%{day: day, month: month} = date)
      when month in [4, 6, 9, 11] and day in 1..30,
      do: {:ok, date}

  def validate_day(%{day: day, month: 2} = date)
      when day in 1..28,
      do: {:ok, date}

  def validate_day(%{day: 29, month: 2, year: year} = date) do
    if Timex.is_leap?(year),
      do: {:ok, date},
      else: :error
  end

  def validate_day(_), do: :error

  defp for_context(:date, parsed_values, false) do
    if parsed_date?(parsed_values) do
      Date.new(parsed_values[:year], parsed_values[:month], parsed_values[:day])
    else
      {:error, :cannot_assume_date}
    end
  end

  defp for_context(:date, parsed_values, true),
    do: {:ok, Map.merge(Date.utc_today(), parsed_values)}

  defp for_context(:date, parsed_values, %Date{} = date),
    do: {:ok, Map.merge(date, parsed_values)}

  defp for_context(:time, _parsed_values, _), do: {:error, "Could not parse a time out of a date"}

  defp for_context(:datetime, _parsed_values, _),
    do: {:error, "Could not parse a datetime out of a date"}

  def parsed_date?(parsed_values) do
    !Enum.any?([parsed_values[:year], parsed_values[:month], parsed_values[:day]], &is_nil/1)
  end
end

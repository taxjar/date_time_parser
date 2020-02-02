defmodule DateTimeParser.Parser.Time do
  @moduledoc false
  @behaviour DateTimeParser.Parser
  @time_regex ~r|(?<time>\d{1,2}:\d{2}(?::\d{2})?(?:.*)?)|

  import NimbleParsec
  import DateTimeParser.Combinators.Time
  import DateTimeParser.Formatters, only: [format_token: 2]

  defparsecp(:do_parse, time())

  @impl DateTimeParser.Parser
  def preflight(parser), do: {:ok, parser}

  @impl DateTimeParser.Parser
  def parse(%{string: string} = parser) do
    case string |> extract_time() |> do_parse() do
      {:ok, tokens, _, _, _, _} -> from_tokens(parser, tokens)
      _ -> {:error, :failed_to_parse}
    end
  end

  def from_tokens(%{context: context}, tokens) do
    case Time.new(
           format_token(tokens, :hour) || 0,
           format_token(tokens, :minute) || 0,
           format_token(tokens, :second) || 0,
           format_token(tokens, :microsecond) || {0, 0}
         ) do
      {:ok, time} -> for_context(context, time)
      _ -> {:error, "Could not parse time"}
    end
  end

  def parsed_time?(parsed_values) do
    !Enum.any?([parsed_values[:hour], parsed_values[:minute]], &is_nil/1)
  end

  defp extract_time(string) do
    case Regex.named_captures(@time_regex, string) do
      %{"time" => time} -> time
      _ -> string
    end
  end

  defp for_context(:time, time), do: {:ok, time}
  defp for_context(:date, time), do: {:error, "Could not parse a date from #{inspect(time)}"}

  defp for_context(:datetime, time),
    do: {:error, "Could not parse a datetime from #{inspect(time)}"}
end

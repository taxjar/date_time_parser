defmodule DateTimeParser.Parser do
  @moduledoc """
  Interface for the DateTimeParser to use when parsing a string.

  The flow is:

  1. Preflight the string to see if the parser is appropriate. Sometimes the parsing can happen at
    this stage if it's a simple parser, for example it can be done in a single regex. Results of the
    preflight, if needed, can be stored in the struct in `:preflight`.
  2. Parse the string. You have `struct.context` to check if you should parse the `:time`, `:date`,
    or `:datetime`. Also make sure you're honoring the user's options supplied in `struct.opts`

  You may create your own parser and use it with the DateTimeParser by creating a module that
  follows this behaviour.
  """

  defstruct [:string, :mod, :preflight, :context, opts: []]

  @type context :: :datetime | :date | :time
  @type t :: %__MODULE__{
          string: String.t(),
          mod: :atom,
          context: context(),
          preflight: any(),
          opts: Keyword.t()
        }

  alias DateTimeParser.Parser

  @doc """
  Determine if the string is appropriate to parse with this parser. If not, then other parsers will
  be attempted.
  """
  @callback preflight(t()) :: {:ok, t()} | {:error, :not_compatible}

  @doc """
  Parse the string.
  """
  @callback parse(t()) ::
              {:ok, DateTime.t() | NaiveDateTime.t() | Time.t() | Date.t()} | {:error, any()}

  @default_parsers [Parser.Epoch, Parser.Serial, Parser.Tokenizer]

  @doc false
  def available_parsers, do: @default_parsers

  @doc "Builds the Parser struct from the given context, string, and options"
  def build(string, context, opts) do
    parser = %__MODULE__{context: context, string: string, opts: opts}

    opts
    |> Keyword.get(:parsers, Application.get_env(:date_time_parser, :parsers, @default_parsers))
    |> Enum.map(&tokenizer_to_parser(&1, context, string))
    |> Enum.find_value({:error, :no_parser}, fn parser_mod ->
      case parser_mod.preflight(parser) do
        {:ok, parser} -> {:ok, %{parser | mod: parser_mod}}
        {:error, _} -> false
      end
    end)
  end

  defp tokenizer_to_parser(:tokenizer, context, string),
    do: get_token_parser(context, string)

  defp tokenizer_to_parser(Parser.Tokenizer, context, string),
    do: get_token_parser(context, string)

  defp tokenizer_to_parser(:epoch, _, _), do: Parser.Epoch
  defp tokenizer_to_parser(:serial, _, _), do: Parser.Serial
  defp tokenizer_to_parser(parser_mod, _, _), do: parser_mod

  defp get_token_parser(:datetime, string) do
    if String.contains?(string, "/") do
      Parser.DateTimeUS
    else
      Parser.DateTime
    end
  end

  defp get_token_parser(:date, string) do
    if String.contains?(string, "/") do
      Parser.DateUS
    else
      Parser.Date
    end
  end

  defp get_token_parser(:time, _string) do
    Parser.Time
  end
end

defmodule DateTimeParser do
  @moduledoc """
  DateTimeParser is a tokenizer for strings that attempts to parse into a `DateTime`,
  `NaiveDateTime` if timezone is not determined, `Date`, or `Time`.

  The biggest ambiguity between datetime formats is whether it's `ymd` (year month day), `mdy`
  (month day year), or `dmy` (day month year); this is resolved by checking if there are slashes or
  dashes. If slashes, then it will try `dmy` first. All other cases will use the international
  format `ymd`. Sometimes, if the conditions are right, it can even parse `dmy` with dashes if the
  month is a vocal month (eg, `"Jan"`).

  If the string is 10-11 digits with optional precision, then we'll try to parse it as a Unix Epoch
  timestamp.

  If the string is 1-5 digits with optional precision, then we'll try to parse it as a Serial
  timestamp (spreadsheet time) treating 1899-12-31 as 1. This will cause Excel-produced dates from
  1900-01-01 until 1900-03-01 to be incorrect, as they really are.

  |digits|parser|range|notes|
  |---|----|---|---|
  |1-5|Serial|low = `1900-01-01`, high = `2173-10-15`. Negative numbers go to `1626-03-17`|Floats indicate time. Integers do not.|
  |6-9|Tokenizer|any|This allows for "20190429" to be parsed as `2019-04-29`|
  |10-11|Epoch|low = `-1100-02-15 14:13:21`, high = `5138-11-16 09:46:39`|If padded with 0s, then it can capture entire range.|
  |else|Tokenizer|any| |

  ## Examples

    ```elixir
    iex> DateTimeParser.parse("19 September 2018 08:15:22 AM")
    {:ok, ~N[2018-09-19 08:15:22]}

    iex> DateTimeParser.parse_datetime("19 September 2018 08:15:22 AM")
    {:ok, ~N[2018-09-19 08:15:22]}

    iex> DateTimeParser.parse_datetime("2034-01-13", assume_time: true)
    {:ok, ~N[2034-01-13 00:00:00]}

    iex> DateTimeParser.parse_datetime("2034-01-13", assume_time: ~T[06:00:00])
    {:ok, ~N[2034-01-13 06:00:00]}

    iex> DateTimeParser.parse("invalid date 10:30pm")
    {:ok, ~T[22:30:00]}

    iex> DateTimeParser.parse("2019-03-11T99:99:99")
    {:ok, ~D[2019-03-11]}

    iex> DateTimeParser.parse("2019-03-11T10:30:00pm UNK")
    {:ok, ~N[2019-03-11T22:30:00]}

    iex> DateTimeParser.parse("2019-03-11T22:30:00.234+00:00")
    {:ok, DateTime.from_naive!(~N[2019-03-11T22:30:00.234Z], "Etc/UTC")}

    iex> DateTimeParser.parse_date("2034-01-13")
    {:ok, ~D[2034-01-13]}

    iex> DateTimeParser.parse_date("01/01/2017")
    {:ok, ~D[2017-01-01]}

    iex> DateTimeParser.parse_datetime("1564154204")
    {:ok, DateTime.from_naive!(~N[2019-07-26T15:16:44Z], "Etc/UTC")}

    iex> DateTimeParser.parse_datetime("1564154204.123")
    {:ok, DateTime.from_naive!(~N[2019-07-26T15:16:44.123Z], "Etc/UTC")}

    iex> DateTimeParser.parse_datetime("-1564154204")
    {:ok, DateTime.from_naive!(~N[1920-06-08T08:43:16Z], "Etc/UTC")}

    iex> DateTimeParser.parse_datetime("-1564154204.123")
    {:ok, DateTime.from_naive!(~N[1920-06-08T08:43:15.877Z], "Etc/UTC")}

    iex> DateTimeParser.parse_datetime("41261.6013888889")
    {:ok, ~N[2012-12-18T14:26:00]}

    iex> DateTimeParser.parse_date("44262")
    {:ok, ~D[2021-03-07]}
    # This is a serial number date, commonly found in spreadsheets, eg: `=VALUE("03/07/2021")`

    iex> DateTimeParser.parse_datetime("1/1/18 3:24 PM")
    {:ok, ~N[2018-01-01T15:24:00]}

    iex> DateTimeParser.parse_datetime("1/1/18 3:24 PM", assume_utc: true)
    {:ok, DateTime.from_naive!(~N[2018-01-01T15:24:00Z], "Etc/UTC")}
    # or ~U[2018-01-01T15:24:00Z] in Elixir 1.9.0+

    iex> DateTimeParser.parse_datetime(~s|"Mar 28, 2018 7:39:53 AM PDT"|, to_utc: true)
    {:ok, DateTime.from_naive!(~N[2018-03-28T14:39:53Z], "Etc/UTC")}

    iex> {:ok, datetime} = DateTimeParser.parse_datetime(~s|"Mar 1, 2018 7:39:53 AM PST"|)
    iex> datetime
    #DateTime<2018-03-01 07:39:53-08:00 PST PST8PDT>

    iex> DateTimeParser.parse_datetime(~s|"Mar 1, 2018 7:39:53 AM PST"|, to_utc: true)
    {:ok, DateTime.from_naive!(~N[2018-03-01T15:39:53Z], "Etc/UTC")}

    iex> {:ok, datetime} = DateTimeParser.parse_datetime(~s|"Mar 28, 2018 7:39:53 AM PDT"|)
    iex> datetime
    #DateTime<2018-03-28 07:39:53-07:00 PDT PST8PDT>

    iex> DateTimeParser.parse_time("10:13pm")
    {:ok, ~T[22:13:00]}

    iex> DateTimeParser.parse_time("10:13:34")
    {:ok, ~T[10:13:34]}

    iex> DateTimeParser.parse_time("18:14:21.145851000000Z")
    {:ok, ~T[18:14:21.145851]}

    iex> DateTimeParser.parse_datetime(nil)
    {:error, "Could not parse nil"}
    ```
  """

  import DateTimeParser.Formatters
  alias DateTimeParser.Parser

  @type assume_date :: {:assume_date, boolean() | Date.t()}
  @type assume_time :: {:assume_time, boolean() | Time.t()}
  @type assume_utc :: {:assume_utc, boolean()}
  @type to_utc :: {:to_utc, boolean()}

  @typedoc "List of modules that implement the `DateTimeParser.Parser` behaviour."
  @type parsers :: {:parsers, list(atom())}

  @typedoc """
  Options for `parse_datetime/2`

  * `:assume_utc` Default `false`.
  Only applicable for strings where parsing could not determine a timezone. Instead of returning a
  NaiveDateTime, this option will assume them to be in UTC timezone, and therefore return a
  DateTime. If the timezone is determined, then it will continue to be returned in the original
  timezone. See `to_utc` option to also convert it to UTC.

  * `:to_utc` Default `false`.
  If there's a timezone detected in the string, then attempt to convert to UTC timezone. If you
  know that your timestamps are in the future and are going to store it for later use, it may be
  better to convert to UTC and keep the original timestamp since government organizations may change
  timezone rules before the timestamp elapses, therefore making the UTC timestamp wrong or invalid.
  [Check out the guide on future timestamps](./future-utc-datetime.html).

  * `:assume_time` Default `false`.
  If a time cannot be determined, then it will not be assumed by default. If you supply `true`, then
  `~T[00:00:00]` will be assumed. You can also supply your own time, and the found tokens will be
  merged with it.

  * `:parsers` Default `#{inspect(DateTimeParser.Parser.available_parsers())}`.
  The parsers to use when analyzing the string. When `Parser.Tokenizer`, the appropriate tokenizer will be
  used depending on the function used.
  """
  @type parse_datetime_options :: [assume_utc() | to_utc() | assume_time() | parsers()]

  @typedoc """
  Options for `parse_date/2`

  * `:assume_date` Default `false`.
  If a date cannot be fully determined, then it will not be assumed by default. If you supply
  `true`, then `Date.utc_today()` will be assumed. You can also supply your own date, and the found
  tokens will be merged with it.
  """
  @type parse_date_options :: [assume_date() | parsers()]

  @typedoc """
  Options for `parse_time/2`.

  See `t:parse_datetime_options/0` for further definition.
  """
  @type parse_time_options :: [parsers()]

  @typedoc """
  Options for `parse/2`.

  Combination of `t:parse_date_options/0` and `t:parse_datetime_options/0` and
  `t:parse_time_options/0`
  """
  @type parse_options :: parse_datetime_options() | parse_date_options() | parse_time_options()

  @doc """
  Parse a `%DateTime{}`, `%NaiveDateTime{}`, `%Date{}`, or `%Time{}` from a string.

  Accepts `t:parse_options/0`
  """
  @spec parse(String.t() | nil, parse_options()) ::
          {:ok, DateTime.t() | NaiveDateTime.t() | Date.t() | Time.t()} | {:error, String.t()}
  def parse(string, opts \\ [])

  def parse(string, opts) when is_binary(string) do
    with {:error, _} <- parse_datetime(string, opts),
         {:error, _} <- parse_date(string, opts) do
      parse_time(string, opts)
    end
  end

  def parse(value, _opts), do: {:error, "Could not parse #{inspect(value)}"}

  @doc """
  Parse a `%DateTime{}`, `%NaiveDateTime{}`, `%Date{}`, or `%Time{}` from a string. Raises a
  `DateTimeParser.ParseError` when parsing fails.

  Accepts `t:parse_options/0`.
  """
  @spec parse!(String.t() | nil, parse_options()) ::
          DateTime.t() | NaiveDateTime.t() | Date.t() | Time.t() | no_return()
  def parse!(string, opts \\ []) do
    case parse(string, opts) do
      {:ok, result} -> result
      {:error, message} -> raise(__MODULE__.ParseError, message)
    end
  end

  @doc """
  Parse a `%DateTime{}` or `%NaiveDateTime{}` from a string.

  Accepts options `t:parse_datetime_options/0`
  """
  @spec parse_datetime(String.t() | nil, parse_datetime_options()) ::
          {:ok, DateTime.t() | NaiveDateTime.t()} | {:error, String.t()}
  def parse_datetime(string, opts \\ [])

  def parse_datetime(string, opts) when is_binary(string) do
    with {:ok, parser} <- string |> clean() |> Parser.build(:datetime, opts),
         {:ok, datetime} <- parser.mod.parse(parser) do
      {:ok, datetime}
    else
      _ ->
        {:error, "Could not parse #{inspect(string)}"}
    end
  end

  def parse_datetime(value, _opts), do: {:error, "Could not parse #{inspect(value)}"}

  @doc """
  Parse a `%DateTime{}` or `%NaiveDateTime{}` from a string. Raises a `DateTimeParser.ParseError` when
  parsing fails.

  Accepts options `t:parse_datetime_options/0`.
  """
  @spec parse_datetime!(String.t() | nil, parse_datetime_options()) ::
          DateTime.t() | NaiveDateTime.t() | no_return()
  def parse_datetime!(string, opts \\ []) do
    case parse_datetime(string, opts) do
      {:ok, result} -> result
      {:error, message} -> raise(__MODULE__.ParseError, message)
    end
  end

  @doc """
  Parse `%Time{}` from a string. Accepts options `t:parse_time_options/0`
  """
  @spec parse_time(String.t() | nil, parse_time_options()) ::
          {:ok, Time.t()} | {:error, String.t()}
  def parse_time(string, opts \\ [])

  def parse_time(string, opts) when is_binary(string) do
    with {:ok, parser} <- string |> clean() |> Parser.build(:time, opts),
         {:ok, time} <- parser.mod.parse(parser) do
      {:ok, time}
    else
      _ ->
        {:error, "Could not parse #{inspect(string)}"}
    end
  end

  def parse_time(value, _opts), do: {:error, "Could not parse #{inspect(value)}"}

  @doc """
  Parse `%Time{}` from a string. Raises a `DateTimeParser.ParseError` when parsing fails.
  """
  @spec parse_time!(String.t() | nil, parse_time_options()) :: Time.t() | no_return()
  def parse_time!(string, opts \\ []) do
    case parse_time(string, opts) do
      {:ok, result} -> result
      {:error, message} -> raise(__MODULE__.ParseError, message)
    end
  end

  @doc """
  Parse `%Date{}` from a string.

  Accepts options `t:parse_date_options/0`
  """
  @spec parse_date(String.t() | nil, parse_date_options()) ::
          {:ok, Date.t()} | {:error, String.t()}
  def parse_date(string, opts \\ [])

  def parse_date(string, opts) when is_binary(string) do
    with {:ok, parser} <- string |> clean() |> Parser.build(:date, opts),
         {:ok, date} <- parser.mod.parse(parser) do
      {:ok, date}
    else
      _ ->
        {:error, "Could not parse #{inspect(string)}"}
    end
  end

  def parse_date(value, _opts), do: {:error, "Could not parse #{inspect(value)}"}

  @doc """
  Parse a `%Date{}` from a string. Raises a `DateTimeParser.ParseError` when parsing fails.

  Accepts options `t:parse_date_options/0`.
  """
  @spec parse_date!(String.t() | nil, parse_datetime_options()) ::
          Date.t() | no_return()
  def parse_date!(string, opts \\ []) do
    case parse_date(string, opts) do
      {:ok, result} -> result
      {:error, message} -> raise(__MODULE__.ParseError, message)
    end
  end
end

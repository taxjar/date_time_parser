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
  alias DateTimeParser.{Epoch, Serial}

  @epoch_regex ~r|\A(?<sign>-)?(?<seconds>\d{10,11})(?:\.(?<subseconds>\d{1,10}))?\z|
  @serial_regex ~r|\A-?\d{1,5}(?:\.\d{1,10})?\z|
  @time_regex ~r|(?<time>\d{1,2}:\d{2}(?::\d{2})?(?:.*)?)|

  @type assume_date :: {:assume_date, boolean() | Date.t()}
  @type assume_time :: {:assume_time, boolean() | Time.t()}
  @type assume_utc :: {:assume_utc, boolean()}
  @type to_utc :: {:to_utc, boolean()}

  @typedoc """
  Options applicable for `parse_datetime/2`

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
  """
  @type parse_datetime_options :: [assume_utc() | to_utc() | assume_time()]

  @typedoc """
  Options applicable for `parse_date/2`

  * `:assume_date` Default `false`.
  If a date cannot be fully determined, then it will not be assumed by default. If you supply
  `true`, then `Date.utc_today()` will be assumed. You can also supply your own date, and the found
  tokens will be merged with it.
  """
  @type parse_date_options :: [assume_date()]

  @typedoc """
  Options for `parse/2`. Combination of `t:parse_date_options/0` and `t:parse_datetime_options/0`.
  """
  @type parse_options :: parse_datetime_options() | parse_date_options()

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
      parse_time(string)
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
    with cleaned_string <- clean(string),
         {:ok, tokens, _, _, _, _} <- do_datetime_parse(cleaned_string),
         {:ok, naive_datetime} <- to_naive_datetime(tokens, opts),
         datetime <- to_datetime(naive_datetime, tokens),
         {:ok, datetime} <- validate_day(datetime),
         datetime <- maybe_convert_to_utc(datetime, opts) do
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

  defp do_datetime_parse(string) do
    cond do
      String.contains?(string, "/") ->
        DateTimeParser.DateTime.parse_us(string)

      epoch_regex_capture = Regex.named_captures(@epoch_regex, string) ->
        Epoch.parse(epoch_regex_capture)

      Regex.match?(@serial_regex, string) ->
        Serial.parse(string)

      true ->
        DateTimeParser.DateTime.parse(string)
    end
  end

  @doc """
  Parse `%Time{}` from a string.
  """
  @spec parse_time(String.t() | nil) :: {:ok, Time.t()} | {:error, String.t()}
  def parse_time(string) when is_binary(string) do
    case string |> clean() |> do_time_parse() do
      {:ok, tokens, _, _, _, _} ->
        to_time(tokens)

      _ ->
        {:error, "Could not parse #{inspect(string)}"}
    end
  end

  def parse_time(value), do: {:error, "Could not parse #{inspect(value)}"}

  @doc """
  Parse `%Time{}` from a string. Raises a `DateTimeParser.ParseError` when parsing fails.
  """
  @spec parse_time!(String.t() | nil) :: Time.t() | no_return()
  def parse_time!(string) do
    case parse_time(string) do
      {:ok, result} -> result
      {:error, message} -> raise(__MODULE__.ParseError, message)
    end
  end

  defp do_time_parse(string) do
    cond do
      epoch_regex_capture = Regex.named_captures(@epoch_regex, string) ->
        Epoch.parse(epoch_regex_capture)

      Regex.match?(@serial_regex, string) ->
        Serial.parse(string)

      true ->
        case Regex.named_captures(@time_regex, string) do
          %{"time" => time} -> DateTimeParser.Time.parse(time)
          _ -> DateTimeParser.Time.parse(string)
        end
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
    with cleaned_string <- clean(string),
         {:ok, tokens, _, _, _, _} <- do_parse_date(cleaned_string),
         {:ok, date} <- to_date(tokens, opts),
         {:ok, _} <- validate_day(date) do
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

  defp do_parse_date(string) do
    cond do
      String.contains?(string, "/") ->
        DateTimeParser.Date.parse_us(string)

      epoch_regex_capture = Regex.named_captures(@epoch_regex, string) ->
        Epoch.parse(epoch_regex_capture)

      Regex.match?(@serial_regex, string) ->
        Serial.parse(string)

      true ->
        DateTimeParser.Date.parse(string)
    end
  end

  defp to_time(tokens) do
    cond do
      tokens[:unix_epoch] ->
        with {:ok, datetime} <- Epoch.from_tokens(tokens) do
          {:ok, DateTime.to_time(datetime)}
        end

      tokens[:serial] ->
        case Serial.from_tokens(tokens, []) do
          {:ok, %NaiveDateTime{} = datetime} ->
            {:ok, NaiveDateTime.to_time(datetime)}

          _ ->
            :error
        end

      true ->
        DateTimeParser.Time.from_tokens(tokens)
    end
  end

  defp to_date(tokens, opts) do
    cond do
      tokens[:serial] ->
        case Serial.from_tokens(tokens, opts) do
          {:ok, %NaiveDateTime{} = naive_datetime} ->
            {:ok, NaiveDateTime.to_date(naive_datetime)}

          {:ok, %Date{} = date} ->
            {:ok, date}

          _ ->
            :error
        end

      tokens[:unix_epoch] ->
        with {:ok, datetime} <- Epoch.from_tokens(tokens),
             %Date{} = date <- DateTime.to_date(datetime) do
          {:ok, date}
        end

      true ->
        DateTimeParser.Date.from_tokens(tokens, opts)
    end
  end

  defp to_naive_datetime(tokens, opts) do
    cond do
      tokens[:serial] ->
        case Serial.from_tokens(tokens, opts) do
          {:ok, %NaiveDateTime{} = naive_datetime} ->
            {:ok, naive_datetime}

          _ ->
            :error
        end

      tokens[:unix_epoch] ->
        Epoch.from_tokens(tokens)

      true ->
        DateTimeParser.DateTime.from_tokens(tokens, opts)
    end
  end

  defp to_datetime(%DateTime{} = datetime, _tokens), do: datetime

  defp to_datetime(%NaiveDateTime{} = naive_datetime, tokens) do
    DateTimeParser.DateTime.from_naive_datetime_and_tokens(naive_datetime, tokens)
  end

  defp validate_day(%{day: day, month: month} = date)
       when month in [1, 3, 5, 7, 8, 10, 12] and day in 1..31,
       do: {:ok, date}

  defp validate_day(%{day: day, month: month} = date)
       when month in [4, 6, 9, 11] and day in 1..30,
       do: {:ok, date}

  defp validate_day(%{day: day, month: 2} = date)
       when day in 1..28,
       do: {:ok, date}

  defp validate_day(%{day: 29, month: 2, year: year} = date) do
    if Timex.is_leap?(year),
      do: {:ok, date},
      else: :error
  end

  defp validate_day(_), do: :error

  defp maybe_convert_to_utc(%NaiveDateTime{} = naive_datetime, opts) do
    if Keyword.get(opts, :assume_utc, false) do
      naive_datetime
      |> DateTime.from_naive!("Etc/UTC")
      |> maybe_convert_to_utc(opts)
    else
      naive_datetime
    end
  end

  defp maybe_convert_to_utc(%DateTime{zone_abbr: "Etc/UTC"} = datetime, _opts), do: datetime

  defp maybe_convert_to_utc(%DateTime{} = datetime, opts) do
    if Keyword.get(opts, :to_utc, false) do
      # empty TimezoneInfo defaults to UTC. Doing this to avoid Dialyzer errors
      # since :utc is not in the typespec
      Timex.Timezone.convert(datetime, %Timex.TimezoneInfo{})
    else
      datetime
    end
  end
end

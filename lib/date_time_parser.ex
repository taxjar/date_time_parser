defmodule DateTimeParser do
  @moduledoc """
  DateTimeParser is a tokenizer for strings that attempts to parse into a `DateTime`,
  `NaiveDateTime` if timezone is not determined, `Date`, or `Time`.

  The biggest ambiguity between datetime formats is whether it's `ymd` (year month day), `mdy`
  (month day year), or `dmy` (day month year); this is resolved by checking if there are slashes or
  dashes. If slashes, then it will try `dmy` first. All other cases will use the international
  format `ymd`. Sometimes, if the conditions are right, it can even parse `dmy` with dashes if the
  month is a vocal month (eg, `"Jan"`).

  If the string is 10-11 digits with optional precision, then we'll try to parse it as a Unix epoch
  timestamp.

  ## Examples

    ```elixir
    iex> DateTimeParser.parse_datetime("19 September 2018 08:15:22 AM")
    {:ok, ~N[2018-09-19 08:15:22]}

    iex> DateTimeParser.parse_datetime("2034-01-13")
    {:ok, ~N[2034-01-13 00:00:00]}

    iex> DateTimeParser.parse_date("2034-01-13")
    {:ok, ~D[2034-01-13]}

    iex> DateTimeParser.parse_date("01/01/2017")
    {:ok, ~D[2017-01-01]}

    iex> DateTimeParser.parse_datetime("1564154204")
    {:ok, DateTime.from_naive!(~N[2019-07-26T15:16:44Z], "Etc/UTC")}

    iex> DateTimeParser.parse_datetime("1/1/18 3:24 PM")
    {:ok, ~N[2018-01-01T15:24:00]}

    iex> DateTimeParser.parse_datetime("1/1/18 3:24 PM", assume_utc: true)
    {:ok, DateTime.from_naive!(~N[2018-01-01T15:24:00Z], "Etc/UTC")}
    # or ~U[2018-01-01T15:24:00Z] in Elixir 1.9.0+

    iex> DateTimeParser.parse_datetime(~s|"Dec 1, 2018 7:39:53 AM PST"|)
    {:ok, DateTime.from_naive!(~N[2018-12-01T14:39:53Z], "Etc/UTC")}
    # Notice that the date is converted to UTC by default

    iex> {:ok, datetime} = DateTimeParser.parse_datetime(~s|"Dec 1, 2018 7:39:53 AM PST"|, to_utc: false)
    iex> datetime
    #DateTime<2018-12-01 07:39:53-07:00 PDT PST8PDT>

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

  @doc """
  Parse a `%DateTime{}` or `%NaiveDateTime{}` from a string.

  Options:
    * `:assume_utc` Default `false`.
    Only applicable for strings where parsing could not determine a timezone. Instead of returning
    a NaiveDateTime, this option will assume them to be in UTC timezone, and therefore return a
    DateTime

    * `:to_utc` Default `true`.
    If there's a timezone detected in the string, then attempt to convert to UTC timezone. This is
    helpful for storing in databases with Ecto.
  """

  import DateTimeParser.Formatters
  alias DateTimeParser.Epoch

  @epoch_regex ~r|\A\d{10,11}(?:\.\d{1,10})?\z|
  @spec parse_datetime(String.t() | nil, Keyword.t()) ::
          {:ok, DateTime.t() | NaiveDateTime.t()} | {:error, String.t()}
  def parse_datetime(string, opts \\ [])

  def parse_datetime(string, opts) when is_binary(string) do
    with string <- clean(string),
         {:ok, tokens, _, _, _, _} <- do_datetime_parse(string),
         naive_datetime <- to_naive_datetime(tokens),
         datetime <- to_datetime(naive_datetime, tokens),
         {:ok, datetime} <- validate_day(datetime),
         datetime <- maybe_convert_to_utc(datetime, opts) do
      {:ok, datetime}
    else
      _ ->
        {:error, "Could not parse #{string}"}
    end
  end

  def parse_datetime(nil, _opts), do: {:error, "Could not parse nil"}
  def parse_datetime(value, _opts), do: {:error, "Could not parse #{value}"}

  def do_datetime_parse(string) do
    cond do
      String.contains?(string, "/") -> DateTimeParser.DateTime.parse_us(string)
      Regex.match?(@epoch_regex, string) -> Epoch.parse(string)
      true -> DateTimeParser.DateTime.parse(string)
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
        {:error, "Could not parse #{string}"}
    end
  end

  def parse_time(nil), do: {:error, "Could not parse nil"}
  def parse_time(value), do: {:error, "Could not parse #{value}"}

  def do_time_parse(string) do
    if Regex.match?(@epoch_regex, string) do
      Epoch.parse(string)
    else
      DateTimeParser.Time.parse(string)
    end
  end

  @doc """
  Parse `%Date{}` from a string.
  """
  @spec parse_date(String.t() | nil) :: {:ok, Date.t()} | {:error, String.t()}
  def parse_date(string) when is_binary(string) do
    with string <- clean(string),
         {:ok, tokens, _, _, _, _} <- do_parse_date(string),
         {:ok, date} <- to_date(tokens),
         {:ok, _} <- validate_day(date) do
      {:ok, date}
    else
      _ ->
        {:error, "Could not parse #{string}"}
    end
  end

  def parse_date(nil), do: {:error, "Could not parse nil"}
  def parse_date(value), do: {:error, "Could not parse #{value}"}

  defp do_parse_date(string) do
    cond do
      String.contains?(string, "/") -> DateTimeParser.Date.parse_us(string)
      Regex.match?(@epoch_regex, string) -> Epoch.parse(string)
      true -> DateTimeParser.Date.parse(string)
    end
  end

  defp to_time(tokens) do
    if tokens[:unix_epoch] do
      with %Time{} = time <- tokens |> Epoch.from_tokens() |> DateTime.to_time() do
        {:ok, time}
      end
    else
      DateTimeParser.Time.from_tokens(tokens)
    end
  end

  defp to_date(tokens) do
    if tokens[:unix_epoch] do
      with %Date{} = date <- tokens |> Epoch.from_tokens() |> DateTime.to_date() do
        {:ok, date}
      end
    else
      DateTimeParser.Date.from_tokens(tokens)
    end
  end

  defp to_naive_datetime(tokens) do
    if tokens[:unix_epoch] do
      Epoch.from_tokens(tokens)
    else
      DateTimeParser.DateTime.from_tokens(tokens)
    end
  end

  defp to_datetime(%DateTime{} = datetime, _tokens), do: datetime

  defp to_datetime(%NaiveDateTime{} = naive_datetime, tokens) do
    case DateTimeParser.DateTime.timezone_from_tokens(tokens) do
      %{} = timezone_info ->
        DateTimeParser.DateTime.from_naive_datetime_and_timezone(naive_datetime, timezone_info)

      _ ->
        naive_datetime
    end
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

  defp maybe_convert_to_utc(%DateTime{} = datetime, opts) do
    if Keyword.get(opts, :to_utc, true) do
      Timex.Timezone.convert(datetime, "Etc/UTC")
    else
      datetime
    end
  end
end

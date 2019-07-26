defmodule DateTimeParser do
  @moduledoc """
  DateTimeParser is a tokenizer for strings that attempts to parse into a
  `DateTime`, `NaiveDateTime` if timezone is not determined, `Date`, or `Time`.

  The biggest ambiguity between datetime formats is whether it's `ymd` (year month
  day), `mdy` (month day year), or `dmy` (day month year); this is resolved by
  checking if there are slashes or dashes. If slashes, then it will try `dmy`
  first. All other cases will use the international format `ymd`. Sometimes, if
  the conditions are right, it can even parse `dmy` with dashes if the month is a
  vocal month (eg, `"Jan"`).

  If the string starts with 10 digits, then we'll try to parse it as a Unix epoch timestamp.

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
  @epoch_regex ~r|(?<!\d)\d{10}\.?\d{0,10}|
  @spec parse_datetime(String.t() | nil, Keyword.t()) ::
          {:ok, DateTime.t() | NaiveDateTime.t()} | {:error, String.t()}
  def parse_datetime(string, opts \\ [])

  def parse_datetime(string, opts) when is_binary(string) do
    parser =
      cond do
        String.contains?(string, "/") -> &DateTimeParser.DateTime.parse_us/1
        Regex.match?(@epoch_regex, string) -> &DateTimeParser.Epoch.parse/1
        true -> &DateTimeParser.DateTime.parse/1
      end

    with {:ok, tokens, _, _, _, _} <- string |> clean() |> parser.(),
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

  @doc """
  Parse `%Time{}` from a string.
  """
  @spec parse_time(String.t() | nil) :: {:ok, Time.t()} | {:error, String.t()}
  def parse_time(string) when is_binary(string) do
    parser =
      if Regex.match?(@epoch_regex, string) do
        &DateTimeParser.Epoch.parse/1
      else
        &DateTimeParser.Time.parse/1
      end

    case string |> clean |> parser.() do
      {:ok, tokens, _, _, _, _} ->
        to_time(tokens)

      _ ->
        {:error, "Could not parse #{string}"}
    end
  end

  def parse_time(nil), do: {:error, "Could not parse nil"}
  def parse_time(value), do: {:error, "Could not parse #{value}"}

  @doc """
  Parse `%Date{}` from a string.
  """
  @spec parse_date(String.t() | nil) :: {:ok, Date.t()} | {:error, String.t()}
  def parse_date(string) when is_binary(string) do
    parser =
      cond do
        String.contains?(string, "/") -> &DateTimeParser.Date.parse_us/1
        Regex.match?(@epoch_regex, string) -> &DateTimeParser.Epoch.parse/1
        true -> &DateTimeParser.Date.parse/1
      end

    with {:ok, tokens, _, _, _, _} <- string |> clean |> parser.(),
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

  defp from_epoch(tokens) do
    with {:ok, datetime} <- DateTime.from_unix(tokens[:unix_epoch]) do
      case tokens[:unix_epoch_subsecond] do
        nil ->
          datetime

        subsecond ->
          truncated_subsecond =
            subsecond
            |> Integer.digits()
            |> Enum.take(6)
            |> Integer.undigits()

          %{datetime | microsecond: format({:microsecond, truncated_subsecond})}
      end
    end
  end

  defp to_time(tokens) do
    if tokens[:unix_epoch] do
      with %Time{} = time <- tokens |> from_epoch() |> DateTime.to_time() do
        {:ok, time}
      end
    else
      Time.new(
        format_token(tokens, :hour) || 0,
        format_token(tokens, :minute) || 0,
        format_token(tokens, :second) || 0,
        format_token(tokens, :microsecond) || {0, 0}
      )
    end
  end

  defp to_date(tokens) do
    if tokens[:unix_epoch] do
      with %Date{} = date <- tokens |> from_epoch() |> DateTime.to_date() do
        {:ok, date}
      end
    else
      Date.new(
        format_token(tokens, :year) || 0,
        format_token(tokens, :month) || 0,
        format_token(tokens, :day) || 0
      )
    end
  end

  defp to_naive_datetime(tokens) do
    if tokens[:unix_epoch] do
      from_epoch(tokens)
    else
      Map.merge(
        NaiveDateTime.utc_now(),
        clean(%{
          year: format_token(tokens, :year),
          month: format_token(tokens, :month),
          day: format_token(tokens, :day),
          hour: format_token(tokens, :hour) || 0,
          minute: format_token(tokens, :minute) || 0,
          second: format_token(tokens, :second) || 0,
          microsecond: format_token(tokens, :microsecond) || {0, 0}
        })
      )
    end
  end

  defp to_datetime(%DateTime{} = datetime, _tokens), do: datetime

  defp to_datetime(naive_datetime, tokens) do
    with zone <- format_token(tokens, :zone_abbr),
         offset <- format_token(tokens, :utc_offset),
         true <- Enum.any?([zone, offset]),
         %{} = timezone_info <- Timex.Timezone.get(offset || zone) do
      naive_datetime
      |> DateTime.from_naive!("Etc/UTC")
      |> Map.merge(%{
        std_offset: timezone_info.offset_std,
        utc_offset: timezone_info.offset_utc,
        zone_abbr: timezone_info.abbreviation,
        time_zone: timezone_info.full_name
      })
    else
      _ -> naive_datetime
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

  defp clean(string) when is_binary(string) do
    string
    |> String.trim()
    |> String.replace(" @ ", "T")
    |> String.replace(~r{[[:space:]]+}, " ")
    |> String.replace(" - ", "-")
    |> String.replace("//", "/")
    |> String.replace(~r{=|"|'|,|\\}, "")
    |> String.downcase()
  end

  defp clean(%{} = map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp format_token(tokens, :hour) do
    case tokens |> find_token(:hour) do
      {:hour, hour} ->
        if tokens |> find_token(:am_pm) |> format == "PM" && hour < 12 do
          hour + 12
        else
          hour
        end

      _ ->
        nil
    end
  end

  defp format_token(tokens, :year) do
    case tokens |> find_token(:year) |> format() do
      nil ->
        nil

      year ->
        year |> to_4_year() |> String.to_integer()
    end
  end

  defp format_token(tokens, token) do
    tokens |> find_token(token) |> format()
  end

  defp find_token(tokens, find_me) do
    Enum.find(tokens, fn
      {token, _} -> token == find_me
      _ -> false
    end)
  end

  # If the parsed two-digit year is 00 to 49, then
  #  - If the last two digits of the current year are 00 to 49, then the returned year has the same
  #    first two digits as the current year.
  #  - If the last two digits of the current year are 50 to 99, then the first 2 digits of the
  #    returned year are 1 greater than the first 2 digits of the current year.
  # If the parsed two-digit year is 50 to 99, then
  #  - If the last two digits of the current year are 00 to 49, then the first 2 digits of the
  #    returned year are 1 less than the first 2 digits of the current year.
  #  - If the last two digits of the current year are 50 to 99, then the returned year has the same
  #    first two digits as the current year.
  defp to_4_year(parsed_3yr) when byte_size(parsed_3yr) == 3 do
    [current_millenia | _rest] =
      DateTime.utc_now()
      |> Map.get(:year)
      |> Integer.digits()

    "#{current_millenia}#{parsed_3yr}"
  end

  defp to_4_year(parsed_2yr) when byte_size(parsed_2yr) == 2 do
    [current_millenia, current_century, current_decade, current_year] =
      DateTime.utc_now()
      |> Map.get(:year)
      |> Integer.digits()

    parsed_2yr = String.to_integer(parsed_2yr)
    current_2yr = String.to_integer("#{current_decade}#{current_year}")

    cond do
      parsed_2yr < 50 && current_2yr < 50 ->
        "#{current_millenia}#{current_century}#{parsed_2yr}"

      parsed_2yr < 50 && current_2yr >= 50 ->
        [_parsed_millenia, parsed_century] =
          [current_millenia, current_century]
          |> Integer.undigits()
          |> Kernel.+(1)
          |> Integer.digits()

        "#{current_millenia}#{parsed_century}#{parsed_2yr}"

      parsed_2yr >= 50 && current_2yr < 50 ->
        [parsed_millenia, parsed_century] =
          [current_millenia, current_century]
          |> Integer.undigits()
          |> Kernel.-(1)
          |> Integer.digits()

        "#{parsed_millenia}#{parsed_century}#{parsed_2yr}"

      parsed_2yr >= 50 && current_2yr >= 50 ->
        "#{current_millenia}#{current_century}#{parsed_2yr}"
    end
  end

  defp to_4_year(parsed_year), do: parsed_year

  defp format({:microsecond, value}) do
    {
      value |> to_string |> String.pad_trailing(6, "0") |> String.to_integer(),
      value |> to_string |> byte_size()
    }
  end

  defp format({:zone_abbr, value}), do: String.upcase(value)
  defp format({:utc_offset, offset}), do: to_string(offset)
  defp format({:year, value}), do: to_string(value)
  defp format({:am_pm, value}), do: String.upcase(value)
  defp format({_, value}) when is_integer(value), do: value
  defp format({_, value}), do: String.to_integer(value)
  defp format(_), do: nil
end

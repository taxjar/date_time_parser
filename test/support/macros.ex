defmodule DateTimeParserTestMacros do
  @moduledoc false
  alias DateTimeParser
  alias DateTimeParserTest.Recorder
  import ExUnit.Assertions

  def to_iso(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)
  def to_iso(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  def to_iso(%Date{} = date), do: Date.to_iso8601(date)
  def to_iso(%Time{} = time), do: Time.to_iso8601(time)
  def to_iso(string) when is_binary(string), do: string

  def run_test(fun, timestamp, expected, opts) do
    case apply(DateTimeParser, fun, [timestamp, opts]) do
      {:ok, result} ->
        case expected do
          %{} = expected ->
            assert result == expected,
                   "Expected #{inspect(expected)} but returned #{inspect(result)} instead"

          expected when is_binary(expected) ->
            assert to_iso(result) == expected,
                   "Expected #{inspect(expected)} but returned #{inspect(result)} instead"
        end

        Recorder.add(
          timestamp,
          expected,
          to_string(fun),
          opts
        )

      error ->
        flunk("""
        #{timestamp} should parse to #{expected}

        Got this instead:
          #{inspect(error)}
        """)
    end
  end

  def test_name(fun, timestamp, []), do: "#{fun} timestamp #{timestamp}"

  def test_name(fun, timestamp, opts),
    do: "#{fun} timestamp #{timestamp} with opts #{inspect(opts)}"

  defmacro test_parsing(timestamp, expected, opts \\ []) do
    quote do
      test_name =
        DateTimeParserTestMacros.test_name(
          :parse,
          unquote(timestamp),
          unquote(opts)
        )

      test test_name do
        DateTimeParserTestMacros.run_test(
          :parse,
          unquote(timestamp),
          unquote(expected),
          unquote(opts)
        )
      end
    end
  end

  defmacro test_datetime_parsing(timestamp, expected, opts \\ []) do
    quote do
      test_name =
        DateTimeParserTestMacros.test_name(
          :parse_datetime,
          unquote(timestamp),
          unquote(opts)
        )

      test test_name do
        DateTimeParserTestMacros.run_test(
          :parse_datetime,
          unquote(timestamp),
          unquote(expected),
          unquote(opts)
        )
      end
    end
  end

  defmacro test_time_parsing(timestamp, expected, opts \\ []) do
    quote do
      test_name =
        DateTimeParserTestMacros.test_name(
          :parse_time,
          unquote(timestamp),
          unquote(opts)
        )

      test test_name do
        DateTimeParserTestMacros.run_test(
          :parse_time,
          unquote(timestamp),
          unquote(expected),
          unquote(opts)
        )
      end
    end
  end

  defmacro test_date_parsing(timestamp, expected, opts \\ []) do
    quote do
      test_name =
        DateTimeParserTestMacros.test_name(
          :parse_date,
          unquote(timestamp),
          unquote(opts)
        )

      test test_name do
        DateTimeParserTestMacros.run_test(
          :parse_date,
          unquote(timestamp),
          unquote(expected),
          unquote(opts)
        )
      end
    end
  end

  def test_error_name(fun, timestamp, []), do: "does not #{fun} timestamp #{timestamp}"

  def test_error_name(fun, timestamp, opts),
    do: "does not #{fun} timestamp #{timestamp} with opts #{inspect(opts)}"

  def run_error_test(fun, timestamp, expected, opts) do
    case apply(DateTimeParser, fun, [timestamp, opts]) do
      {_ok_or_error, message}
      when expected != message and not is_nil(expected) ->
        flunk("""
        #{timestamp} should not have parsed. Opts #{inspect(opts)}

        Expected error:
          #{expected}

        Got this instead:
          #{inspect(message)}
        """)

      {:error, message} ->
        if expected do
          assert message == expected,
                 "Expected error message #{inspect(expected)} but returned #{inspect(message)} instead"
        end

        Recorder.add(
          timestamp,
          message,
          to_string(fun),
          opts
        )
    end
  end

  defmacro test_error(timestamp, expected_message \\ nil, opts \\ []) do
    quote do
      test_name =
        DateTimeParserTestMacros.test_error_name(
          :parse,
          unquote(timestamp),
          unquote(opts)
        )

      test test_name do
        DateTimeParserTestMacros.run_error_test(
          :parse,
          unquote(timestamp),
          unquote(expected_message),
          unquote(opts)
        )
      end
    end
  end

  defmacro test_datetime_error(timestamp, expected_message \\ nil, opts \\ []) do
    quote do
      test_name =
        DateTimeParserTestMacros.test_error_name(
          :parse_datetime,
          unquote(timestamp),
          unquote(opts)
        )

      test test_name do
        DateTimeParserTestMacros.run_error_test(
          :parse_datetime,
          unquote(timestamp),
          unquote(expected_message),
          unquote(opts)
        )
      end
    end
  end

  defmacro test_date_error(timestamp, expected_message \\ nil, opts \\ []) do
    quote do
      test_name =
        DateTimeParserTestMacros.test_error_name(
          :parse_date,
          unquote(timestamp),
          unquote(opts)
        )

      test test_name do
        DateTimeParserTestMacros.run_error_test(
          :parse_date,
          unquote(timestamp),
          unquote(expected_message),
          unquote(opts)
        )
      end
    end
  end

  defmacro test_time_error(timestamp, expected_message \\ nil, opts \\ []) do
    quote do
      test_name =
        DateTimeParserTestMacros.test_error_name(
          :parse_time,
          unquote(timestamp),
          unquote(opts)
        )

      test test_name do
        DateTimeParserTestMacros.run_error_test(
          :parse_time,
          unquote(timestamp),
          unquote(expected_message),
          unquote(opts)
        )
      end
    end
  end
end

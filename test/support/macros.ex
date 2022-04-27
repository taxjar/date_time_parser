defmodule DateTimeParserTestMacros do
  @moduledoc false
  alias DateTimeParser
  alias DateTimeParserTest.Recorder

  def to_iso(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)
  def to_iso(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  def to_iso(%Date{} = date), do: Date.to_iso8601(date)
  def to_iso(%Time{} = time), do: Time.to_iso8601(time)
  def to_iso(string) when is_binary(string), do: string

  defmacro test_parsing(string_timestamp, expected_result, opts \\ []) do
    quote do
      test_name =
        if unquote(opts) == [] do
          "parses timestamp #{unquote(string_timestamp)}"
        else
          "parses timestamp #{unquote(string_timestamp)} with opts #{inspect(unquote(opts))}"
        end

      test test_name do
        assert {:ok, result} = DateTimeParser.parse(unquote(string_timestamp), unquote(opts))

        case unquote(expected_result) do
          %{} = expected ->
            assert result == expected

          expected when is_binary(expected) ->
            assert to_iso(result) == expected
        end

        Recorder.add(unquote(string_timestamp), unquote(expected_result), "parse", unquote(opts))
      end
    end
  end

  defmacro test_datetime_parsing(string_datetime, expected_result, opts \\ []) do
    quote do
      test_name =
        if unquote(opts) == [] do
          "parses datetime #{unquote(string_datetime)}"
        else
          "parses datetime #{unquote(string_datetime)} with opts #{inspect(unquote(opts))}"
        end

      test test_name do
        assert {:ok, datetime} =
                 DateTimeParser.parse_datetime(unquote(string_datetime), unquote(opts))

        case unquote(expected_result) do
          %{} = expected ->
            assert datetime == expected

          expected when is_binary(expected) ->
            assert to_iso(datetime) == expected
        end

        Recorder.add(
          unquote(string_datetime),
          unquote(expected_result),
          "parse_datetime",
          unquote(opts)
        )
      end
    end
  end

  defmacro test_time_parsing(string_time, expected_result) do
    quote do
      test "parses time #{unquote(string_time)}" do
        assert {:ok, time} = DateTimeParser.parse_time(unquote(string_time))
        assert time == unquote(expected_result)
        Recorder.add(unquote(string_time), unquote(expected_result), "parse_time", [])
      end
    end
  end

  defmacro test_date_parsing(string_date, expected_result, opts \\ []) do
    quote do
      test_name =
        if unquote(opts) == [] do
          "parses date #{unquote(string_date)}"
        else
          "parses date #{unquote(string_date)} with opts #{inspect(unquote(opts))}"
        end

      test test_name do
        assert {:ok, date} = DateTimeParser.parse_date(unquote(string_date), unquote(opts))
        assert date == unquote(expected_result)
        Recorder.add(unquote(string_date), unquote(expected_result), "parse_date", unquote(opts))
      end
    end
  end

  defmacro test_error(string_timestamp, expected_message \\ nil, opts \\ []) do
    quote do
      test_name =
        if unquote(opts) == [] do
          "does not parse timestamp #{unquote(string_timestamp)}"
        else
          "does not parse timestamp #{unquote(string_timestamp)} with opts #{inspect(unquote(opts))}"
        end

      test test_name do
        assert {:error, message} = DateTimeParser.parse(unquote(string_timestamp), unquote(opts))

        if unquote(expected_message) do
          assert message == unquote(expected_message)
        end

        Recorder.add(unquote(string_timestamp), message, "parse", unquote(opts))
      end
    end
  end

  defmacro test_datetime_error(string_timestamp, expected_message \\ nil, opts \\ []) do
    quote do
      test_name =
        if unquote(opts) == [] do
          "does not parse datetime #{unquote(string_timestamp)}"
        else
          "does not parse datetime #{unquote(string_timestamp)} with opts #{inspect(unquote(opts))}"
        end

      test test_name do
        assert {:error, message} =
                 DateTimeParser.parse_datetime(unquote(string_timestamp), unquote(opts))

        if unquote(expected_message) do
          assert message == unquote(expected_message)
        end

        Recorder.add(unquote(string_timestamp), message, "parse_datetime", unquote(opts))
      end
    end
  end

  defmacro test_date_error(string_timestamp, expected_message \\ nil, opts \\ []) do
    quote do
      test_name =
        if unquote(opts) == [] do
          "does not parse date #{unquote(string_timestamp)}"
        else
          "does not parse date #{unquote(string_timestamp)} with opts #{inspect(unquote(opts))}"
        end

      test test_name do
        assert {:error, message} =
                 DateTimeParser.parse_date(unquote(string_timestamp), unquote(opts))

        if unquote(expected_message) do
          assert message == unquote(expected_message)
        end

        Recorder.add(unquote(string_timestamp), message, "parse_date", unquote(opts))
      end
    end
  end

  defmacro test_time_error(string_time, expected_message) do
    quote do
      test "does not parse time #{unquote(string_time)}" do
        assert {:error, expected_message} = DateTimeParser.parse_time(unquote(string_time))

        if unquote(expected_message) do
          assert message == unquote(expected_message)
        end

        Recorder.add(unquote(string_time), unquote(expected_message), "parse_time", [])
      end
    end
  end
end

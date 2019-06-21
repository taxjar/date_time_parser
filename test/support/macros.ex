defmodule DateTimeParserTestMacros do
  @moduledoc false
  alias DateTimeParser

  @example_file "EXAMPLES.md"

  def to_iso(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)
  def to_iso(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  def to_iso(%Date{} = date), do: Date.to_iso8601(date)
  def to_iso(%Time{} = time), do: Time.to_iso8601(time)
  def to_iso(string) when is_binary(string), do: string

  def record_result!(method, input, output) do
    File.write!(
      @example_file,
      "|#{method}|`#{input}`|`#{to_iso(output)}`|\n",
      [:append]
    )
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

        record_result!("parse_datetime", unquote(string_datetime), unquote(expected_result))
      end
    end
  end

  defmacro test_time_parsing(string_time, expected_result) do
    quote do
      test "parses time #{unquote(string_time)}" do
        assert {:ok, time} = DateTimeParser.parse_time(unquote(string_time))
        assert time == unquote(expected_result)
        record_result!("parse_time", unquote(string_time), unquote(expected_result))
      end
    end
  end

  defmacro test_date_parsing(string_date, expected_result) do
    quote do
      test "parses date #{unquote(string_date)}" do
        assert {:ok, date} = DateTimeParser.parse_date(unquote(string_date))
        assert date == unquote(expected_result)
        record_result!("parse_date", unquote(string_date), unquote(expected_result))
      end
    end
  end
end

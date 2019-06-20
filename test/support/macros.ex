defmodule DateTimeParserTestMacros do
  @moduledoc false
  alias DateTimeParser

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
          %{} = expected_result ->
            assert datetime == expected_result

          expected_result when is_binary(expected_result) ->
            result =
              case datetime do
                %NaiveDateTime{} = datetime -> NaiveDateTime.to_iso8601(datetime)
                %DateTime{} = datetime -> DateTime.to_iso8601(datetime)
              end

            assert result == expected_result
        end
      end
    end
  end

  defmacro test_time_parsing(string_time, expected_result) do
    quote do
      test "parses time #{unquote(string_time)}" do
        assert {:ok, time} = DateTimeParser.parse_time(unquote(string_time))
        assert time == unquote(expected_result)
      end
    end
  end

  defmacro test_date_parsing(string_date, expected_result) do
    quote do
      test "parses date #{unquote(string_date)}" do
        assert {:ok, date} = DateTimeParser.parse_date(unquote(string_date))
        assert date == unquote(expected_result)
      end
    end
  end
end

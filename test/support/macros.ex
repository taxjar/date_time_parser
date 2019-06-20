defmodule DateTimeParserTestMacros do
  alias DateTimeParser

  defmacro test_parsing(string_datetime, expected_result) do
    quote do
      test "parses #{unquote(string_datetime)}" do
        assert {:ok, datetime} = DateTimeParser.parse(unquote(string_datetime))
        case unquote(expected_result) do
          %{} = expected_result ->
            assert datetime == expected_result
          expected_result when is_binary(expected_result) ->
            result = case datetime do
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
      test "parses #{unquote(string_time)}" do
        assert {:ok, time} = DateTimeParser.parse_time(unquote(string_time))
        assert time == unquote(expected_result)
      end
    end
  end
end

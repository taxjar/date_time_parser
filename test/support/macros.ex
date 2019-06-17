defmodule DateTimeParserTestMacros do
  alias DateTimeParser

  defmacro test_parsing(string_datetime, expected_result) do
    quote do
      test "parses #{unquote(string_datetime)}" do
        assert {:ok, datetime} = DateTimeParser.parse(unquote(string_datetime))
        assert datetime == unquote(expected_result)
      end
    end
  end

  defmacro test_time_parsing(string_time, expected_result) do
    quote do
      test "parses #{unquote(string_time)}" do
        assert {:ok, datetime} = DateTimeParser.parse_time(unquote(string_time))
        assert datetime == unquote(expected_result)
      end
    end
  end
end

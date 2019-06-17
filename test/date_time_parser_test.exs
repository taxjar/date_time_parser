defmodule DateTimeParserTest do
  use ExUnit.Case, async: true
  import DateTimeParserTestMacros
  alias DateTimeParser

  describe "parse/1" do
    test_parsing "02/06/2019", ~N[2019-02-06 00:00:00Z]
    test_parsing "1-9-34", ~N[2034-01-09 00:00:00Z]
    test_parsing "1-9-2034", ~N[2034-01-09 00:00:00Z]
    test_parsing "01-09-2034", ~N[2034-01-09 00:00:00Z]
    test_parsing "1/13/2019", ~N[2019-01-13 00:00:00Z]
    test_parsing ~s|""=\""9/5/2018\"""|, ~N[2018-09-05 00:00:00]
    test_parsing "1/13/19", ~N[2019-01-13 00:00:00Z]
    test_parsing "34-1-13", ~N[2034-01-13 00:00:00Z]
    test_parsing "2034-1-9", ~N[2034-01-09 00:00:00Z]
    test_parsing "2034-01-13", ~N[2034-01-13 00:00:00Z]
    test_parsing "1/15/2019 3:06", ~N[2019-01-15 03:06:00Z]
    test_parsing "19 September 2018 10:15:22 AM", ~N[2018-09-19 10:15:22]
    test_parsing "19 September 2018 02:33:08 PM", ~N[2018-09-19 14:33:08]
    test_parsing "November 29, 2016", ~N[2016-11-29 00:00:00]
    test_parsing "11 July 2017 1:43:46 PM", ~N[2017-07-11 13:43:46]
    test_parsing "Sep-19-16", ~N[2016-09-19 00:00:00]
    test_parsing "9/4/2018 0:00", ~N[2018-09-04 00:00:00]
    test_parsing "9/1/2018 10:26", ~N[2018-09-01 10:26:00]
    test_parsing "9-Feb-18", ~N[2018-02-09 00:00:00]
    test_parsing "2017/11/04 15:20:47 UTC", DateTime.from_naive!(~N[2017-11-04 15:20:47Z], "Etc/UTC")
    test_parsing "2017/11/04 15:20:47 EDT", DateTime.from_naive!(~N[2017-11-04 19:20:47Z], "Etc/UTC")
    test_parsing "2017/11/04 15:20:47 EST", DateTime.from_naive!(~N[2017-11-04 20:20:47Z], "Etc/UTC")
    test_parsing "2017/11/04 15:20:47-0500", DateTime.from_naive!(~N[2017-11-04 20:20:47Z], "Etc/UTC")
    test_parsing "2017-11-04 15:20:47 UTC", DateTime.from_naive!(~N[2017-11-04 15:20:47Z], "Etc/UTC")
    test_parsing "2017-11-04 15:20:47 EST", DateTime.from_naive!(~N[2017-11-04 20:20:47Z], "Etc/UTC")
    test_parsing "2017-11-04 15:20:47-0500", DateTime.from_naive!(~N[2017-11-04 20:20:47Z], "Etc/UTC")

    test "returns an error when not recognized" do
      assert DateTimeParser.parse("384934898234") == {:error, "Could not determine format of timestamp: 384934898234"}
      assert DateTimeParser.parse(384934898234) == {:error, "Could not determine format of timestamp: 384934898234"}
      assert DateTimeParser.parse(nil) == {:error, "Could not parse nil"}
    end
  end
end

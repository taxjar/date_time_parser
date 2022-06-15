defmodule DateTimeParserTest do
  use ExUnit.Case, async: true
  import DateTimeParserTestMacros
  import ExUnit.CaptureLog
  alias DateTimeParser
  alias DateTimeParser.Parser

  if Version.match?(System.version(), ">= 1.5.0") do
    doctest DateTimeParser
  end

  describe "config" do
    test "parse/2, can turn off parsers" do
      assert {:error, _} = DateTimeParser.parse("000", parsers: [])
      assert {:ok, _} = DateTimeParser.parse("000", parsers: [Parser.Serial])

      assert {:error, _} = DateTimeParser.parse("0000000001", parsers: [])
      assert {:ok, _} = DateTimeParser.parse("0000000001", parsers: [Parser.Epoch])

      assert {:error, _} = DateTimeParser.parse("2019-01-01", parsers: [])
      assert {:ok, _} = DateTimeParser.parse("2019-01-01", parsers: [Parser.Tokenizer])

      assert capture_log(fn ->
               assert {:ok, _} = DateTimeParser.parse("000", parsers: [:serial])
             end) =~ "Using :serial is deprecated"

      assert capture_log(fn ->
               assert {:ok, _} = DateTimeParser.parse("0000000001", parsers: [:epoch])
             end) =~ "Using :epoch is deprecated"

      assert capture_log(fn ->
               assert {:ok, _} = DateTimeParser.parse("2019-01-01", parsers: [:tokenizer])
             end) =~ "Using :tokenizer is deprecated"

      assert {:error, _} = DateTimeParser.parse("2019-01-01", parsers: [])
    end

    test "parse_date/2, can turn off parsers" do
      assert {:error, _} = DateTimeParser.parse_date("000", parsers: [])
      assert {:ok, %Date{}} = DateTimeParser.parse_date("000", parsers: [Parser.Serial])

      assert {:error, _} = DateTimeParser.parse_date("0000000001", parsers: [])
      assert {:ok, %Date{}} = DateTimeParser.parse_date("0000000001", parsers: [Parser.Epoch])

      assert {:error, _} = DateTimeParser.parse_date("2019-01-01", parsers: [])
      assert {:ok, %Date{}} = DateTimeParser.parse_date("2019-01-01", parsers: [Parser.Tokenizer])

      assert capture_log(fn ->
               assert {:ok, %Date{}} = DateTimeParser.parse_date("000", parsers: [:serial])
             end) =~ "Using :serial is deprecated"

      assert capture_log(fn ->
               assert {:ok, %Date{}} = DateTimeParser.parse_date("0000000001", parsers: [:epoch])
             end) =~ "Using :epoch is deprecated"

      assert capture_log(fn ->
               assert {:ok, %Date{}} =
                        DateTimeParser.parse_date("2019-01-01", parsers: [:tokenizer])
             end) =~ "Using :tokenizer is deprecated"
    end

    test "parse_time/2, can turn off parsers" do
      assert {:error, _} = DateTimeParser.parse_time("000.0", parsers: [])
      assert {:ok, %Time{}} = DateTimeParser.parse_time("000.0", parsers: [Parser.Serial])

      assert {:error, _} = DateTimeParser.parse_time("0000000001", parsers: [])
      assert {:ok, %Time{}} = DateTimeParser.parse_time("0000000001", parsers: [Parser.Epoch])

      assert {:error, _} = DateTimeParser.parse_time("10:30", parsers: [])
      assert {:ok, %Time{}} = DateTimeParser.parse_time("10:30", parsers: [Parser.Tokenizer])

      assert capture_log(fn ->
               assert {:ok, %Time{}} = DateTimeParser.parse_time("10:30", parsers: [:tokenizer])
             end) =~ "Using :tokenizer is deprecated"

      assert capture_log(fn ->
               assert {:ok, %Time{}} = DateTimeParser.parse_time("000.0", parsers: [:serial])
             end) =~ "Using :serial is deprecated"

      assert capture_log(fn ->
               assert {:ok, %Time{}} = DateTimeParser.parse_time("0000000001", parsers: [:epoch])
             end) =~ "Using :epoch is deprecated"
    end

    test "parse_datetime/2, can turn off parsers" do
      assert {:error, _} = DateTimeParser.parse_datetime("100.0", parsers: [])

      assert {:ok, %NaiveDateTime{}} =
               DateTimeParser.parse_datetime("100.0", parsers: [Parser.Serial])

      assert {:error, _} = DateTimeParser.parse_datetime("0000000001", parsers: [])

      assert {:ok, %DateTime{}} =
               DateTimeParser.parse_datetime("0000000001", parsers: [Parser.Epoch])

      assert {:error, _} = DateTimeParser.parse_datetime("2019-01-01T10:30:00", parsers: [])

      assert {:ok, %NaiveDateTime{}} =
               DateTimeParser.parse_datetime("2019-01-01T10:30:00", parsers: [Parser.Tokenizer])

      assert capture_log(fn ->
               assert {:ok, %NaiveDateTime{}} =
                        DateTimeParser.parse_datetime("100.0", parsers: [:serial])
             end) =~ "Using :serial is deprecated"

      assert capture_log(fn ->
               assert {:ok, %DateTime{}} =
                        DateTimeParser.parse_datetime("0000000001", parsers: [:epoch])
             end) =~ "Using :epoch is deprecated"

      assert capture_log(fn ->
               assert {:ok, %NaiveDateTime{}} =
                        DateTimeParser.parse_datetime("2019-01-01T10:30:00", parsers: [:tokenizer])
             end) =~ "Using :tokenizer is deprecated"
    end
  end

  describe "compare with Ruby/Rails datetime parsing" do
    test_parsing(" 01 Feb 2013", "2013-02-01")
    test_parsing(" 03 Jan 2013 10:15:26 -0800", "2013-01-03T18:15:26Z", to_utc: true)
    test_parsing(" 10/1/2018  :: AM", "2018-10-01")
    test_parsing(" 11 Feb 2013", "2013-02-11")
    test_parsing(" 11 Jan 2013 13:26:55 -0800", "2013-01-11T21:26:55Z", to_utc: true)
    test_parsing(" 12/26/2016", "2016-12-26")
    test_parsing(" 24 Sep 2013", "2013-09-24")
    test_parsing("01-01-2018", "2018-01-01")
    test_parsing("01-Feb-18", "2018-02-01")
    test_parsing("01-Jul", "2019-07-01", assume_date: ~D[2019-01-05])
    test_parsing("01-Jul-18", "2018-07-01")
    test_parsing("01.09.2018", "2018-09-01")
    test_parsing("01.11.2018", "2018-11-01")
    test_parsing("01/01/17", "2017-01-01")
    test_parsing("01/01/2017", "2017-01-01")
    test_parsing("01/01/2018 - 17:06", "2018-01-01T17:06:00")
    test_parsing("01/01/2018 01:21PM", "2018-01-01T13:21:00")
    test_parsing("01/01/2018 14:44", "2018-01-01T14:44:00")
    test_parsing("01/01/2018 6:22", "2018-01-01T06:22:00")
    test_parsing("01/02/16", "2016-01-02")
    test_parsing("01/02/18 01:02 AM", "2018-01-02T01:02:00")
    test_parsing("01/02/2015", "2015-01-02")
    test_parsing("01/Jun./2018", "2018-06-01")
    test_parsing("02-05-2018", "2018-05-02")
    test_parsing("02-Oct-17", "2017-10-02")
    test_parsing("02/01/17", "2017-02-01")
    test_parsing("02/01/2018", "2018-02-01")
    test_parsing("02/21/2018  9:37:42 AM", "2018-02-21T09:37:42")
    test_parsing("03/5/2018", "2018-03-05")
    test_parsing("2010/01/01", "2010-01-01")
    test_parsing("05/01/2018 0:00", "2018-05-01T00:00:00")
    test_parsing("06/14/2018 09:42:08 PM-0500", "2018-06-15T02:42:08Z", to_utc: true)
    test_parsing("06/28/18 1:25", "2018-06-28T01:25:00")
    test_parsing("1-Apr", "2019-04-01", assume_date: ~D[2019-01-13])
    test_error("1-Apr")
    # Ruby parses this next one incorrectly
    test_parsing("1//1/17", "2017-01-01")
    test_parsing("1/1/0117", "0117-01-01")
    test_parsing("1/1/17 19:12", "2017-01-01T19:12:00")
    test_parsing("1/1/18 00:01", "2018-01-01T00:01:00")
    test_parsing("1/1/18 3:24 PM", "2018-01-01T15:24:00")
    test_parsing("1/1/19 10:39 AM", "2019-01-01T10:39:00")
    test_parsing("1/1/2013", "2013-01-01")
    test_parsing("1/10/2018  8:38pM", "2018-01-10T20:38:00")
    test_parsing("1/17/2018 0:00:00", "2018-01-17T00:00:00")
    test_parsing("1/2/2018 18:06:26", "2018-01-02T18:06:26")
    test_parsing("1/3/2019 12:00:00 AM", "2019-01-03T00:00:00")
    test_parsing("1/31/2018 0:00:00 UTC", "2018-01-31T00:00:00Z")
    test_parsing("5/12/2019 12:21:58 PM", "2019-05-12T12:21:58")
    test_parsing("2011-01-01 04:19:20 -0:00", "2011-01-01T04:19:20Z")
    test_parsing("2012-11-23T22:42:25-05:00", "2012-11-24T03:42:25Z", to_utc: true)
    test_parsing("2013-12-31T22:18:50+00:00", "2013-12-31T22:18:50Z")
    test_parsing("10/2/2017 - 23:14", "2017-10-02T23:14:00")
    test_parsing("10/5/2017 23:52", "2017-10-05T23:52:00")
    test_parsing("18-07-2018 20:38:34 +00:00", "2018-07-18T20:38:34Z")
    test_parsing("18-12-29", "2018-12-29")
    test_parsing("19-Dec-19", "2019-12-19")
    test_parsing("2012-10-30 09:52:00", "2012-10-30T09:52:00")
    test_parsing("2013-04-26 11:25:03 UTC", "2013-04-26T11:25:03Z")
    test_parsing("2013-09-10 22:14:56.717", "2013-09-10T22:14:56.717")
    test_parsing("2016-11-17 10:36:34.81", "2016-11-17T10:36:34.81")
    test_parsing("2015-09-28 10:57:11 -0700", "2015-09-28T17:57:11Z", to_utc: true)
    test_parsing("2015/12/1 1:16", "2015-12-01T01:16:00")
    test_parsing("2016-04-30", "2016-04-30")
    test_parsing("2016-05-02T01:10:06+00:00", "2016-05-02T01:10:06Z")
    test_parsing("2016-06-11 15:50:43", "2016-06-11T15:50:43")
    test_parsing("2016-06-16 06:06:06", "2016-06-16T06:06:06")
    test_parsing("2016-07-01 01:51:34+00", "2016-07-01T01:51:34Z")
    test_parsing("2016-07-31 18:42:46-07:00", "2016-08-01T01:42:46Z", to_utc: true)
    test_parsing("2016-08-04T07:00:25Z", "2016-08-04T07:00:25Z")
    test_parsing("2016-08-19 09:34:51.0", "2016-08-19T09:34:51.0")
    test_parsing("2016-11-23T16:25:33.971897", "2016-11-23T16:25:33.971897")
    test_parsing("2016/1/9", "2016-01-09")
    test_parsing("2017-09-29+00:00", "2017-09-29T00:00:00")
    test_parsing("2017-10-06+03:45:16", "2017-10-06T03:45:16")
    test_parsing("2017-10-24 04:00:10 PDT", "2017-10-24T11:00:10Z", to_utc: true)
    test_parsing("2017-12-01 03:52", "2017-12-01T03:52:00")
    test_parsing("2017/08/08", "2017-08-08")
    test_parsing("2019/01/31 0:01", "2019-01-31T00:01:00")
    test_parsing("29/Aug./2018", "2018-08-29")
    test_parsing("29/Sep./2018", "2018-09-29")
    test_parsing("9/10/2018 11:08:13 AM", "2018-09-10T11:08:13")
    test_parsing("9/19/2018 20:38", "2018-09-19T20:38:00")
    test_parsing("9/20/2017 18:57:24 UTC", "2017-09-20T18:57:24Z")
    test_parsing(~s|"=\""10/1/2018\"""|, "2018-10-01")
    test_parsing(~s|"=\""9/5/2018\"""|, "2018-09-05")
    test_parsing(~s|"Apr 1, 2016 12:02:53 AM PDT"|, "2016-04-01T07:02:53Z", to_utc: true)
    test_parsing(~s|"Apr 1, 2017 2:21:25 AM PDT"|, "2017-04-01T09:21:25Z", to_utc: true)
    test_parsing(~s|"Dec 1, 2018 7:39:53 AM PST"|, "2018-12-01T15:39:53Z", to_utc: true)
    test_parsing("Fri Mar  2 09:01:57 2018", "2018-03-02T09:01:57")
    test_parsing("Sun Jul  1 00:31:18 2018", "2018-07-01T00:31:18")
    test_parsing("Fri Mar 31 2017 21:41:40 GMT+0000 (UTC)", "2017-03-31T21:41:40Z")
    test_parsing("Friday 02 February 2018 10:42:21 AM", "2018-02-02T10:42:21")
    test_parsing(~s|"Jan 1, 2013 06:34:31 PM PST"|, "2013-01-02T02:34:31Z", to_utc: true)
    test_parsing(~s|"Jan 1, 2014 6:44:47 AM PST"|, "2014-01-01T14:44:47Z", to_utc: true)
    test_parsing(~s|"Mar 28, 2014 6:44:47 AM PDT"|, "2014-03-28T13:44:47Z", to_utc: true)
    test_parsing("Jan-01-19", "2019-01-01")
    test_parsing("Jan-01-19", "2019-01-01T00:00:00", assume_time: true)
    test_parsing("Jan-01-19", "2019-01-01T10:13:15", assume_time: ~T[10:13:15])
    test_parsing("Jan-01-2018", "2018-01-01")
    test_parsing("Monday 01 October 2018 06:34:19 AM", "2018-10-01T06:34:19")
    test_parsing("Monday 02 October 2017 9:04:49 AM", "2017-10-02T09:04:49")
    test_parsing(~s|"Nov 16, 2017 9:41:28 PM PST"|, "2017-11-17T05:41:28Z", to_utc: true)
    # This isn't a valid time with PM specified
    test_parsing(~s|"Nov 20, 2016 22:09:23 PM"|, "2016-11-20T22:09:23")
    test_parsing(~s|"Sat, 29 Sep 2018 21:36:28 -0400"|, "2018-09-30T01:36:28Z", to_utc: true)
    test_parsing(~s|"September 28, 2016"|, "2016-09-28")
    test_parsing("Sun Jan 08 2017 04:28:42 GMT+0000 (UTC)", "2017-01-08T04:28:42Z")
    test_parsing("Sunday 01 January 2017 09:22:46 AM", "2017-01-01T09:22:46")
    test_parsing("Sunday 01 January 2017 10:11:02 PM", "2017-01-01T22:11:02")
    test_parsing("Thu Aug 09 2018 17:13:43 GMT+0000 (UTC)", "2018-08-09T17:13:43Z")
    test_parsing("Thu Feb 08 00:24:33 2018", "2018-02-08T00:24:33")
    test_parsing("Thu Jul  5 12:19:56 2018", "2018-07-05T12:19:56")
    test_parsing("Tue Jul 31 06:44:39 2018", "2018-07-31T06:44:39")
    test_parsing("Thursday 30 August 2018 11:31:18 AM", "2018-08-30T11:31:18")
    test_parsing("Tuesday 11 July 2017 1:43:46 PM", "2017-07-11T13:43:46")
    test_parsing(~s|"Tuesday, November 29, 2016"|, "2016-11-29")
    test_parsing("jul-10-18", "2018-07-10")
  end

  describe "parse_datetime/1 - serial" do
    test_datetime_parsing("41261.6013888889", ~N[2012-12-18T14:26:00])
    test_datetime_parsing("-45103.1454398148", ~N[1776-07-04T20:30:34])
    test_datetime_parsing("-363.0", ~N[1899-01-01T00:00:00])
    test_datetime_parsing("2.0", ~N[1900-01-01T00:00:00])
    test_datetime_parsing("62.0", ~N[1900-03-02T00:00:00])
  end

  describe "parse/1 - serial options" do
    test_parsing("62", ~N[1900-03-02T00:00:00], assume_time: true)
    test_parsing("62", ~N[1904-03-03T00:00:00], assume_time: true, use_1904_date_system: true)
    test_parsing("30134", ~D[1982-07-02])
    test_parsing("30134.0", ~N[1982-07-02T00:00:00])
    test_parsing("62.0", ~N[1900-03-02T00:00:00])
    test_parsing("62.0", ~N[1904-03-03T00:00:00], use_1904_date_system: true)
    test_datetime_parsing("62.0", ~N[1904-03-03T00:00:00], use_1904_date_system: true)
  end

  describe "parse_datetime/1 - epoch" do
    test_datetime_parsing("99999999999", DateTime.from_naive!(~N[5138-11-16T09:46:39], "Etc/UTC"))
    test_datetime_parsing("9999999999", DateTime.from_naive!(~N[2286-11-20T17:46:39], "Etc/UTC"))

    test_datetime_parsing(
      "9999999999.009",
      DateTime.from_naive!(~N[2286-11-20T17:46:39.009], "Etc/UTC")
    )

    test_datetime_parsing(
      "9999999999.090",
      DateTime.from_naive!(~N[2286-11-20T17:46:39.090], "Etc/UTC")
    )

    test_datetime_parsing(
      "9999999999.900",
      DateTime.from_naive!(~N[2286-11-20T17:46:39.900], "Etc/UTC")
    )

    test_datetime_parsing(
      "9999999999.999",
      DateTime.from_naive!(~N[2286-11-20T17:46:39.999], "Etc/UTC")
    )

    test_datetime_parsing(
      "9999999999.999999",
      DateTime.from_naive!(~N[2286-11-20T17:46:39.999999], "Etc/UTC")
    )

    test_datetime_parsing(
      "9999999999.0000000009",
      DateTime.from_naive!(~N[2286-11-20T17:46:39.000000], "Etc/UTC")
    )

    test_datetime_parsing(
      "9999999999.0000009000",
      DateTime.from_naive!(~N[2286-11-20T17:46:39.000000], "Etc/UTC")
    )

    test_datetime_parsing(
      "9999999999.9999999999",
      DateTime.from_naive!(~N[2286-11-20T17:46:39.999999], "Etc/UTC")
    )

    test_datetime_parsing("0000000000", DateTime.from_naive!(~N[1970-01-01T00:00:00], "Etc/UTC"))

    test_datetime_parsing("-0000000001", DateTime.from_naive!(~N[1969-12-31T23:59:59], "Etc/UTC"))

    test_datetime_parsing(
      "-0000000001.0000000001",
      DateTime.from_naive!(~N[1969-12-31T23:59:58.000000], "Etc/UTC")
    )

    # example from the Wikipedia article
    test_datetime_parsing("-0386380800", DateTime.from_naive!(~N[1957-10-04T00:00:00], "Etc/UTC"))
    test_datetime_parsing("-9999999999", DateTime.from_naive!(~N[1653-02-10T06:13:21], "Etc/UTC"))

    if Version.match?(System.version(), ">= 1.7.0") do
      test_datetime_parsing(
        "-99999999999",
        NaiveDateTime.new(-1199, 2, 15, 14, 13, 21) |> elem(1) |> DateTime.from_naive!("Etc/UTC")
      )
    end

    test_datetime_parsing(
      "-9999999999.9999999999",
      DateTime.from_naive!(~N[1653-02-10T06:13:20.000001], "Etc/UTC")
    )
  end

  describe "parse_datetime/1 - MDY" do
    test_datetime_parsing("02/06/2019", ~N[2019-02-06 00:00:00], assume_time: true)
    test_datetime_parsing("1/9/34", ~N[2034-01-09 00:00:00], assume_time: true)
    test_datetime_parsing("1/9/2034", ~N[2034-01-09 00:00:00], assume_time: true)
    test_datetime_parsing("01/09/2034", ~N[2034-01-09 00:00:00], assume_time: true)
    test_datetime_parsing("9/4/2018 0:00", ~N[2018-09-04 00:00:00])
    test_datetime_parsing("9/1/2018 10:26", ~N[2018-09-01 10:26:00], assume_time: true)
    test_datetime_parsing("1/13/2019", ~N[2019-01-13 00:00:00], assume_time: true)
    test_datetime_parsing(~s|""=\""9/5/2018\"""|, ~N[2018-09-05 00:00:00], assume_time: true)
    test_datetime_parsing("1/13/19", ~N[2019-01-13 00:00:00], assume_time: true)
    test_datetime_parsing("1/15/2019 3:06", ~N[2019-01-15 03:06:00])
    test_datetime_parsing("4/24/2019 0:00:00", ~N[2019-04-24 00:00:00])
    test_datetime_parsing("5/2/2019 0:00:00", ~N[2019-05-02 00:00:00])
    test_datetime_parsing("5/31/2019 12:00:00 AM", ~N[2019-05-31 00:00:00])
    test_datetime_parsing("5/2/2019 12:00:00 AM", ~N[2019-05-02 00:00:00])
  end

  describe "parse_date/1 - MDY" do
    test_date_parsing("02/06/2019", ~D[2019-02-06])
    test_date_parsing("1/9/34", ~D[2034-01-09])
    test_date_parsing("1/9/2034", ~D[2034-01-09])
    test_date_parsing("01/09/2034", ~D[2034-01-09])
    test_date_parsing("9/4/2018 0:00", ~D[2018-09-04])
    test_date_parsing("9/1/2018 10:26", ~D[2018-09-01])
    test_date_parsing("1/13/2019", ~D[2019-01-13])
    test_date_parsing(~s|""=\""9/5/2018\"""|, ~D[2018-09-05])
    test_date_parsing("1/13/19", ~D[2019-01-13])
    test_date_parsing("1/15/2019 3:06", ~D[2019-01-15])
    test_date_parsing("4/24/2019 0:00:00", ~D[2019-04-24])
    test_date_parsing("5/2/2019 0:00:00", ~D[2019-05-02])
    test_date_parsing("5/31/2019 12:00:00 AM", ~D[2019-05-31])
    test_date_parsing("5/2/2019 12:00:00 AM", ~D[2019-05-02])
    test_date_parsing("2/5", ~D[2021-02-05], assume_date: ~D[2021-01-01])
    test_date_parsing("12/5", ~D[2021-12-05], assume_date: ~D[2021-01-01])
    test_date_parsing("13/5", ~D[2021-05-13], assume_date: ~D[2021-01-01])
  end

  describe "parse_datetime/1 - DMY" do
    test_datetime_parsing("23-05-2019 @ 10:01", ~N[2019-05-23 10:01:00], assume_time: true)
    test_datetime_parsing("9-Feb-18", ~N[2018-02-09 00:00:00], assume_time: true)
    test_datetime_parsing("9-2-32", ~N[2032-02-09 00:00:00], assume_time: true)
  end

  describe "parse_date/1 - DMY" do
    test_date_parsing("23-05-2019 @ 10:01", ~D[2019-05-23])
    test_date_parsing("9-Feb-18", ~D[2018-02-09])
    test_date_parsing("9-2-32", ~D[2032-02-09])
  end

  describe "parse_date/1 - MY" do
    test_date_parsing("Jan 2020", ~D[2020-01-01], assume_date: ~D[0001-12-01])
    test_date_parsing("October 1995", ~D[1995-10-01], assume_date: ~D[0001-12-01])
    test_date_parsing("May 1442", ~D[1442-05-01], assume_date: ~D[0001-12-01])
  end

  describe "parse_datetime/1 - YMD" do
    test_datetime_parsing("2021-03-27 12:00 am", ~N[2021-03-27 00:00:00])
    test_datetime_parsing("2021-03-27 12:00 pm", ~N[2021-03-27 12:00:00])

    # The AM/PM here is essentially ignored.
    test_datetime_parsing("2021-03-27 00:00 am", ~N[2021-03-27 00:00:00])
    test_datetime_parsing("2021-03-27 00:00 pm", ~N[2021-03-27 00:00:00])

    test_datetime_parsing("2019-05-16+04:00", ~N[2019-05-16 04:00:00], assume_time: true)
    test_datetime_parsing("34-1-13", ~N[2034-01-13 00:00:00], assume_time: true)
    test_datetime_parsing("2034-1-9", ~N[2034-01-09 00:00:00], assume_time: true)
    test_datetime_parsing("20340109", ~N[2034-01-09 00:00:00], assume_time: true)
    test_datetime_parsing("2034-01-13", ~N[2034-01-13 00:00:00], assume_time: true)
    test_datetime_parsing("2016-02-29 00:00:00 UTC", "2016-02-29T00:00:00Z")

    test_datetime_parsing(
      "2017-11-04 15:20:47 UTC",
      DateTime.from_naive!(~N[2017-11-04 15:20:47Z], "Etc/UTC")
    )

    test_datetime_parsing(
      "2017-11-04 15:20:47 EDT",
      DateTime.from_naive!(~N[2017-11-04 19:20:47Z], "Etc/UTC"),
      to_utc: true
    )

    test_datetime_parsing(
      "2017-11-04 15:20:47 EST",
      DateTime.from_naive!(~N[2017-11-04 20:20:47Z], "Etc/UTC"),
      to_utc: true
    )

    test_datetime_parsing(
      "2017-11-04 15:20:47-0500",
      DateTime.from_naive!(~N[2017-11-04 20:20:47Z], "Etc/UTC"),
      to_utc: true
    )

    test_datetime_parsing(
      "2017-11-04 15:20:47+0500",
      DateTime.from_naive!(~N[2017-11-04 10:20:47Z], "Etc/UTC"),
      to_utc: true
    )

    test_datetime_parsing(
      "2017-11-04 15:20:47+0000",
      DateTime.from_naive!(~N[2017-11-04 15:20:47Z], "Etc/UTC")
    )

    test_datetime_parsing(
      "2019-05-20 10:00:00PST",
      DateTime.from_naive!(~N[2019-05-20 17:00:00Z], "Etc/UTC"),
      to_utc: true
    )
  end

  describe "parse_date/1 - YMD" do
    test_date_parsing("2019-05-16+04:00", ~D[2019-05-16])
    test_date_parsing("34-1-13", ~D[2034-01-13])
    test_date_parsing("2034-1-9", ~D[2034-01-09])
    test_date_parsing("2034-01-13", ~D[2034-01-13])
    test_date_parsing("2017-11-04 15:20:47 UTC", ~D[2017-11-04])
    test_date_parsing("2017-11-04 15:20:47 EDT", ~D[2017-11-04])
    test_date_parsing("2017-11-04 15:20:47 EST", ~D[2017-11-04])
    test_date_parsing("2017-11-04 15:20:47-0500", ~D[2017-11-04])
    test_date_parsing("2017-11-04 15:20:47+0500", ~D[2017-11-04])
    test_date_parsing("2017-11-04 15:20:47+0000", ~D[2017-11-04])
    test_date_parsing("2019-05-20 10:00:00PST", ~D[2019-05-20])
    test_date_parsing("2016-02-29", ~D[2016-02-29])
  end

  describe "parse_datetime/2 - options" do
    test "to_utc: false returns NaiveDateTime when undetermined timezone" do
      string = "2019-01-01T00:00:00"
      {:ok, result} = DateTimeParser.parse_datetime(string, to_utc: false)

      assert result == ~N[2019-01-01 00:00:00]
    end

    test "to_utc: false returns DateTime when determined timezone" do
      string = "2019-01-01T00:00:00Z"
      {:ok, result} = DateTimeParser.parse_datetime(string, to_utc: false)

      assert result == DateTime.from_naive!(~N[2019-01-01 00:00:00], "Etc/UTC")
    end

    test "to_utc: true returns converted DateTime when timezone is determined" do
      string = "2019-01-01T00:00:00 PST"
      {:ok, result} = DateTimeParser.parse_datetime(string, to_utc: true)

      assert result == DateTime.from_naive!(~N[2019-01-01 08:00:00], "Etc/UTC")
    end

    test "to_utc: true returns NaiveDateTime when timezone is undetermined" do
      string = "2019-01-01T08:00:00"
      {:ok, result} = DateTimeParser.parse_datetime(string, to_utc: true)

      assert result == ~N[2019-01-01 08:00:00]
    end

    test "assume_utc: false returns NaiveDateTime when undetermined timezone" do
      string = "2019-01-01T00:00:00"
      {:ok, result} = DateTimeParser.parse_datetime(string, assume_utc: false)

      assert result == ~N[2019-01-01 00:00:00]
    end

    test "assume_utc: false returns DateTime when determined timezone" do
      string = "2019-01-01T00:00:00Z"
      {:ok, result} = DateTimeParser.parse_datetime(string, assume_utc: false)

      assert result == DateTime.from_naive!(~N[2019-01-01 00:00:00], "Etc/UTC")
    end

    test "assume_utc: true returns timezoned DateTime when timezone is determined" do
      string = "2019-01-01T00:00:00 PST"
      {:ok, result} = DateTimeParser.parse_datetime(string, assume_utc: true)
      naive_datetime_result = DateTime.to_naive(result)

      assert naive_datetime_result == ~N[2019-01-01 00:00:00]

      assert %{zone_abbr: "PST", time_zone: "PST8PDT", utc_offset: -28_800, std_offset: 0} =
               result
    end

    test "assume_utc: true returns NaiveDateTime when timezone is undetermined" do
      string = "2019-01-01T08:00:00"
      {:ok, result} = DateTimeParser.parse_datetime(string, assume_utc: true)

      assert result == DateTime.from_naive!(~N[2019-01-01 08:00:00], "Etc/UTC")
    end
  end

  describe "parse_datetime/1 - vocal" do
    test_datetime_parsing("Sunday 01 January 2017 10:11:02 PM", ~N[2017-01-01 22:11:02])
    test_datetime_parsing("Sunday, 01 January 2017 10:11:02 PM", ~N[2017-01-01 22:11:02])
    test_datetime_parsing("Sun, 01 January 2017 10:11:02 PM", ~N[2017-01-01 22:11:02])
    test_datetime_parsing("Sun 01 January 2017 10:11:02 PM", ~N[2017-01-01 22:11:02])
    test_datetime_parsing("November 29, 2016", ~N[2016-11-29 00:00:00], assume_time: true)

    test_datetime_parsing(
      "May 30, 2019 4:31:09 AM PDT",
      DateTime.from_naive!(~N[2019-05-30 11:31:09], "Etc/UTC"),
      to_utc: true
    )

    test_datetime_parsing("Sep-19-16", ~N[2016-09-19 00:00:00], assume_time: true)

    test_datetime_parsing(
      "Oct 5, 2018 6:16:56 PM PDT",
      DateTime.from_naive!(~N[2018-10-06 01:16:56Z], "Etc/UTC"),
      to_utc: true
    )

    test_datetime_parsing("19 September 2018 08:15:22 AM", ~N[2018-09-19 08:15:22])
    test_datetime_parsing("19 September 18 2:33:08 PM", ~N[2018-09-19 14:33:08])
    test_datetime_parsing("11 July 2017 1:43:46 PM", ~N[2017-07-11 13:43:46])
  end

  describe "parse_date/1 - vocal" do
    test_date_parsing("Sunday 01 January 2017 10:11:02 PM", ~D[2017-01-01])
    test_date_parsing("Sunday, 01 January 2017 10:11:02 PM", ~D[2017-01-01])
    test_date_parsing("Sun, 01 January 2017 10:11:02 PM", ~D[2017-01-01])
    test_date_parsing("Sun 01 January 2017 10:11:02 PM", ~D[2017-01-01])
    test_date_parsing("November 29, 2016", ~D[2016-11-29])
    test_date_parsing("May 30, 2019 4:31:09 AM PDT", ~D[2019-05-30])
    test_date_parsing("Sep-19-16", ~D[2016-09-19])
    test_date_parsing("Oct 5, 2018 6:16:56 PM PDT", ~D[2018-10-05])
    test_date_parsing("19 September 2018 08:15:22 AM", ~D[2018-09-19])
    test_date_parsing("19 September 18 2:33:08 PM", ~D[2018-09-19])
    test_date_parsing("11 July 2017 1:43:46 PM", ~D[2017-07-11])
  end

  describe "parse_date/1 - epoch" do
    test_date_parsing("99999999999", ~D[5138-11-16])
    test_date_parsing("9999999999", ~D[2286-11-20])
    test_date_parsing("9999999999.009", ~D[2286-11-20])
    test_date_parsing("9999999999.999", ~D[2286-11-20])
    test_date_parsing("9999999999.999999", ~D[2286-11-20])
    test_date_parsing("9999999999.9999999999", ~D[2286-11-20])
    test_date_parsing("0000000000", ~D[1970-01-01])
    test_date_parsing("-0000000001", ~D[1969-12-31])
    test_date_parsing("-0000000001.001", ~D[1969-12-31])
    test_date_parsing("-0000000001.111111", ~D[1969-12-31])
    test_date_parsing("-9999999999.009", ~D[1653-02-10])
    test_date_parsing("-9999999999.999", ~D[1653-02-10])
    test_date_parsing("-9999999999.999999", ~D[1653-02-10])
    test_date_parsing("-9999999999.9999999999", ~D[1653-02-10])
  end

  describe "parse_date/1 - serial" do
    test_date_parsing("41261.6013888889", ~D[2012-12-18])
    test_date_parsing("-45103.1454398148", ~D[1776-07-04])
    test_date_parsing("-363", ~D[1899-01-01])
    test_date_parsing("2", ~D[1900-01-01])
    test_date_parsing("62", ~D[1900-03-02])
  end

  describe "parse_time/1" do
    test_time_parsing("00:00.0", ~T[00:00:00])
    test_time_parsing("07:09.3", ~T[07:09:00])
    test_time_parsing("08:53.0", ~T[08:53:00])
    test_time_parsing("10:13.7", ~T[10:13:00])
    test_time_parsing("12:30PM", ~T[12:30:00], assume_date: ~D[2020-01-01])
    test_time_error("24:00", "Could not parse \"24:00\"")
    test_parsing("12:30PM", ~N[2020-01-01 12:30:00], assume_date: ~D[2020-01-01])
  end

  describe "parse_time/1 - epoch" do
    test_time_parsing("99999999999", ~T[09:46:39])
    test_time_parsing("9999999999", ~T[17:46:39])
    test_time_parsing("9999999999.000001", ~T[17:46:39.000001])
    test_time_parsing("9999999999.000010", ~T[17:46:39.000010])
    test_time_parsing("9999999999.000100", ~T[17:46:39.000100])
    test_time_parsing("9999999999.001000", ~T[17:46:39.001000])
    test_time_parsing("9999999999.010000", ~T[17:46:39.010000])
    test_time_parsing("9999999999.100000", ~T[17:46:39.100000])
    test_time_parsing("9999999999.009", ~T[17:46:39.009])
    test_time_parsing("9999999999.900", ~T[17:46:39.900])
    test_time_parsing("9999999999.999", ~T[17:46:39.999])
    test_time_parsing("9999999999.999999", ~T[17:46:39.999999])
    test_time_parsing("9999999999.9999999999", ~T[17:46:39.999999])
    test_time_parsing("0000000000", ~T[00:00:00])
    test_time_parsing("-9999999999.9999999999", ~T[06:13:20.000001])
    test_time_parsing("-9999999999.999999", ~T[06:13:20.000001])
    test_time_parsing("-9999999999.99999", ~T[06:13:20.00001])
    test_time_parsing("-9999999999.9999", ~T[06:13:20.0001])
    test_time_parsing("-9999999999.999", ~T[06:13:20.001])
    test_time_parsing("-9999999999.99", ~T[06:13:20.01])
    test_time_parsing("-9999999999.9", ~T[06:13:20.1])
    test_time_parsing("-0000000001.0000000001", ~T[23:59:58.000000])
    test_time_parsing("-0000000001.000001", ~T[23:59:58.999999])
    test_time_parsing("-0000000001.00001", ~T[23:59:58.99999])
    test_time_parsing("-0000000001.0001", ~T[23:59:58.9999])
    test_time_parsing("-0000000001.001", ~T[23:59:58.999])
    test_time_parsing("-0000000001.01", ~T[23:59:58.99])
    test_time_parsing("-0000000001.1", ~T[23:59:58.9])
  end

  describe "parse_time/1 - serial" do
    test_time_parsing("41261.6013888889", ~T[14:26:00])
    test_time_parsing("-45103.1454398148", ~T[20:30:34])
  end

  describe "bang variants" do
    test "parse! successfully returns results" do
      assert %NaiveDateTime{} = DateTimeParser.parse!("2019-01-01T01:01:01")
      assert %DateTime{} = DateTimeParser.parse!("2019-01-01T01:01:01Z")
      assert %Date{} = DateTimeParser.parse!("2019-01-01")
      assert %Time{} = DateTimeParser.parse!("9:30pm")
    end

    test "parse! raises an error when fails to parse" do
      assert_raise DateTimeParser.ParseError, ~s|Could not parse "foo"|, fn ->
        DateTimeParser.parse!("foo")
      end
    end

    test "parse_datetime! successfully returns results" do
      assert %NaiveDateTime{} = DateTimeParser.parse_datetime!("2019-01-01T01:01:01")
      assert %DateTime{} = DateTimeParser.parse_datetime!("2019-01-01T01:01:01Z")
    end

    test "parse_datetime! raises an error when fails to parse" do
      assert_raise DateTimeParser.ParseError, ~s|Could not parse "foo"|, fn ->
        DateTimeParser.parse_datetime!("foo")
      end
    end

    test "parse_date! successfully returns results" do
      assert %Date{} = DateTimeParser.parse_date!("2019-01-01")
    end

    test "parse_date! raises an error when fails to parse" do
      assert_raise DateTimeParser.ParseError, ~s|Could not parse "foo"|, fn ->
        DateTimeParser.parse_date!("foo")
      end
    end

    test "parse_time! successfully returns results" do
      assert %Time{} = DateTimeParser.parse_time!("10:30pm")
    end

    test "parse_time! raises an error when fails to parse" do
      assert_raise DateTimeParser.ParseError, ~s|Could not parse "foo"|, fn ->
        DateTimeParser.parse_time!("foo")
      end
    end
  end

  describe "errors" do
    test "returns an error when not recognized" do
      assert DateTimeParser.parse_datetime("2017-24-32 16:09:53 UTC") ==
               {:error, ~s|Could not parse "2017-24-32 16:09:53 UTC"|}

      assert DateTimeParser.parse_datetime("2017-01-01 25:00 am") ==
               {:error, ~s|Could not parse "2017-01-01 25:00 am"|}

      assert DateTimeParser.parse_datetime("2017-01-01 41:00 am") ==
               {:error, ~s|Could not parse "2017-01-01 41:00 am"|}

      assert DateTimeParser.parse_datetime("2017-01-01 9000:00 am") ==
               {:error, ~s|Could not parse "2017-01-01 9000:00 am"|}

      assert DateTimeParser.parse_datetime("2017-01-01 24:00:00") ==
               {:error, ~s|Could not parse "2017-01-01 24:00:00"|}

      assert DateTimeParser.parse_datetime("2017-01-01 99:00:00") ==
               {:error, ~s|Could not parse "2017-01-01 99:00:00"|}

      assert DateTimeParser.parse_datetime("2017-01-01 00:99:00") ==
               {:error, ~s|Could not parse "2017-01-01 00:99:00"|}

      assert DateTimeParser.parse_datetime("2017-01-01 00:00:99") ==
               {:error, ~s|Could not parse "2017-01-01 00:00:99"|}

      assert DateTimeParser.parse_datetime(nil) == {:error, "Could not parse nil"}
      assert DateTimeParser.parse_date(nil) == {:error, "Could not parse nil"}
      assert DateTimeParser.parse_time(nil) == {:error, "Could not parse nil"}
      assert DateTimeParser.parse(nil) == {:error, "Could not parse nil"}

      assert DateTimeParser.parse({:ok, "foo"}) == {:error, ~s|Could not parse {:ok, "foo"}|}
      assert DateTimeParser.parse_date({:ok, "foo"}) == {:error, ~s|Could not parse {:ok, "foo"}|}
      assert DateTimeParser.parse_time({:ok, "foo"}) == {:error, ~s|Could not parse {:ok, "foo"}|}

      assert DateTimeParser.parse_datetime({:ok, "foo"}) ==
               {:error, ~s|Could not parse {:ok, "foo"}|}
    end

    test_error("01-Jul", ~s|Could not parse "01-Jul"|)
    test_datetime_error("01-Jul")
    test_datetime_error("2017-02-29 00:00:00 UTC")
    test_date_error("2017-02-29")

    for month <- ~w[04 06 09 11] do
      @month month

      test_datetime_error(
        "2017-#{@month}-31 00:00:00 UTC",
        ~s|Could not parse "2017-#{@month}-31 00:00:00 UTC"|
      )

      test_date_error("2017-#{@month}-31", ~s|Could not parse "2017-#{@month}-31"|)
    end
  end
end

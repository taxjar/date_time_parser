defmodule DateTimeParserTest do
  use ExUnit.Case, async: true
  import DateTimeParserTestMacros
  alias DateTimeParser

  describe "compare with Ruby/Rails date parsing" do
    test_parsing " 01 Feb 2013", "2013-02-01T00:00:00"
    test_parsing " 03 Jan 2013 10:15:26 -0800", "2013-01-03T18:15:26Z"
    test_parsing " 10/1/2018  :: AM", "2018-10-01T00:00:00"
    test_parsing " 11 Feb 2013", "2013-02-11T00:00:00"
    test_parsing " 11 Jan 2013 13:26:55 -0800", "2013-01-11T21:26:55Z"
    test_parsing " 12/26/2016", "2016-12-26T00:00:00"
    test_parsing " 24 Sep 2013", "2013-09-24T00:00:00"
    test_parsing "01-01-2018", "2018-01-01T00:00:00"
    test_parsing "01-Feb-18", "2018-02-01T00:00:00"
    test_parsing "01-Jul", "2019-07-01T00:00:00"
    test_parsing "01-Jul-18", "2018-07-01T00:00:00"
    test_parsing "01.09.2018", "2018-09-01T00:00:00"
    test_parsing "01.11.2018", "2018-11-01T00:00:00"
    test_parsing "01/01/17", "2017-01-01T00:00:00"
    test_parsing "01/01/2017", "2017-01-01T00:00:00"
    test_parsing "01/01/2018 - 17:06", "2018-01-01T17:06:00"
    test_parsing "01/01/2018 01:21PM", "2018-01-01T13:21:00"
    test_parsing "01/01/2018 14:44", "2018-01-01T14:44:00"
    test_parsing "01/01/2018 6:22", "2018-01-01T06:22:00"
    test_parsing "01/02/16", "2016-01-02T00:00:00"
    test_parsing "01/02/18 01:02 AM", "2018-01-02T01:02:00"
    test_parsing "01/02/2015", "2015-01-02T00:00:00"
    test_parsing "01/Jun./2018", "2018-06-01T00:00:00"
    test_parsing "02-05-2018", "2018-05-02T00:00:00"
    test_parsing "02-Oct-17", "2017-10-02T00:00:00"
    test_parsing "02/01/17", "2017-02-01T00:00:00"
    test_parsing "02/01/2018", "2018-02-01T00:00:00"
    test_parsing "02/21/2018  9:37:42 AM", "2018-02-21T09:37:42"
    test_parsing "03/5/2018", "2018-03-05T00:00:00"
    test_parsing "05/01/2018 0:00", "2018-05-01T00:00:00"
    test_parsing "06/14/2018 09:42:08 PM-0500", "2018-06-15T02:42:08Z"
    test_parsing "06/28/18 1:25", "2018-06-28T01:25:00"
    test_parsing "1-Apr", "2019-04-01T00:00:00"
    # Ruby parses this next one incorrectly
    test_parsing "1//1/17", "2017-01-01T00:00:00"
    test_parsing "1/1/0117", "0117-01-01T00:00:00"
    test_parsing "1/1/17 19:12", "2017-01-01T19:12:00"
    test_parsing "1/1/18 00:01", "2018-01-01T00:01:00"
    test_parsing "1/1/18 3:24 PM", "2018-01-01T15:24:00"
    test_parsing "1/1/19 10:39 AM", "2019-01-01T10:39:00"
    test_parsing "1/1/2013", "2013-01-01T00:00:00"
    test_parsing "1/10/2018  8:38pM", "2018-01-10T20:38:00"
    test_parsing "1/17/2018 0:00:00", "2018-01-17T00:00:00"
    test_parsing "1/2/2018 18:06:26", "2018-01-02T18:06:26"
    test_parsing "1/3/2019 12:00:00 AM", "2019-01-03T12:00:00"
    test_parsing "1/31/2018 0:00:00 UTC", "2018-01-31T00:00:00Z"
    test_parsing "2011-01-01 04:19:20 -0:00", "2011-01-01T04:19:20Z"
    test_parsing "2012-11-23T22:42:25-05:00", "2012-11-24T03:42:25Z"
    test_parsing "2013-12-31T22:18:50+00:00", "2013-12-31T22:18:50Z"
    test_parsing "10/2/2017 - 23:14", "2017-10-02T23:14:00"
    test_parsing "10/5/2017 23:52", "2017-10-05T23:52:00"
    test_parsing "18-07-2018 20:38:34 +00:00", "2018-07-18T20:38:34Z"
    test_parsing "18-12-29", "2018-12-29T00:00:00"
    test_parsing "19-Dec-19", "2019-12-19T00:00:00"
    test_parsing "2012-10-30 09:52:00", "2012-10-30T09:52:00"
    test_parsing "2013-04-26 11:25:03 UTC", "2013-04-26T11:25:03Z"
    # microsecond precision, is this right?
    #test_parsing "2013-09-10 22:14:56.717", "2013-09-10T22:14:56.717"
    # test_parsing "2016-11-17 10:36:34.81", "2016-11-17T10:36:34.00"
    test_parsing "2015-09-28 10:57:11 -0700", "2015-09-28T17:57:11Z"
    test_parsing "2015/12/1 1:16", "2015-12-01T01:16:00"
    test_parsing "2016-04-30", "2016-04-30T00:00:00"
    test_parsing "2016-05-02T01:10:06+00:00", "2016-05-02T01:10:06Z"
    test_parsing "2016-06-11 15:50:43", "2016-06-11T15:50:43"
    test_parsing "2016-06-16 06:06:06", "2016-06-16T06:06:06"
    test_parsing "2016-07-01 01:51:34+00", "2016-07-01T01:51:34Z"
    test_parsing "2016-07-31 18:42:46-07:00", "2016-08-01T01:42:46Z"
    test_parsing "2016-08-04T07:00:25Z", "2016-08-04T07:00:25Z"
    test_parsing "2016-08-19 09:34:51.0", "2016-08-19T09:34:51.0"
    test_parsing "2016-11-23T16:25:33.971897", "2016-11-23T16:25:33.971897"
    test_parsing "2016/1/9", "2016-01-09T00:00:00"
    test_parsing "2017-09-29+00:00", "2017-09-29T00:00:00"
    test_parsing "2017-10-06+03:45:16", "2017-10-06T03:45:16"
    test_parsing "2017-10-24 04:00:10 PDT", "2017-10-24T11:00:10Z"
    test_parsing "2017-12-01 03:52", "2017-12-01T03:52:00"
    test_parsing "2017/08/08", "2017-08-08T00:00:00"
    test_parsing "2019/01/31 0:01", "2019-01-31T00:01:00"
    # Ruby gets the time wrong
    test_parsing "20190118 949 CST", "2019-01-18T14:49:00Z"
    test_parsing "29/Aug./2018", "2018-08-29T00:00:00"
    test_parsing "29/Sep./2018", "2018-09-29T00:00:00"
    test_parsing "9/10/2018 11:08:13 AM", "2018-09-10T11:08:13"
    test_parsing "9/19/2018 20:38", "2018-09-19T20:38:00"
    test_parsing "9/20/2017 18:57:24 UTC", "2017-09-20T18:57:24Z"
    test_parsing ~s|"=\""10/1/2018\"""|, "2018-10-01T00:00:00"
    test_parsing ~s|"=\""9/5/2018\"""|, "2018-09-05T00:00:00"
    test_parsing ~s|"Apr 1, 2016 12:02:53 AM PDT"|, "2016-04-01T19:02:53Z"
    test_parsing ~s|"Apr 1, 2017 2:21:25 AM PDT"|, "2017-04-01T09:21:25Z"
    test_parsing ~s|"Dec 1, 2018 7:39:53 AM PST"|, "2018-12-01T14:39:53Z"
    test_parsing "Fri Mar  2 09:01:57 2018", "2018-03-02T09:01:57"
    test_parsing "Sun Jul  1 00:31:18 2018", "2018-07-01T00:31:18"
    test_parsing "Fri Mar 31 2017 21:41:40 GMT+0000 (UTC)", "2017-03-31T21:41:40Z"
    test_parsing "Friday 02 February 2018 10:42:21 AM", "2018-02-02T10:42:21"
    test_parsing ~s|"Jan 1, 2013 06:34:31 PM PST"|, "2013-01-02T01:34:31Z"
    test_parsing ~s|"Jan 1, 2014 6:44:47 AM PST"|, "2014-01-01T13:44:47Z"
    test_parsing "Jan-01-19", "2019-01-01T00:00:00"
    test_parsing "Jan-01-2018", "2018-01-01T00:00:00"
    test_parsing "Monday 01 October 2018 06:34:19 AM", "2018-10-01T06:34:19"
    test_parsing "Monday 02 October 2017 9:04:49 AM", "2017-10-02T09:04:49"
    test_parsing ~s|"Nov 16, 2017 9:41:28 PM PST"|, "2017-11-17T04:41:28Z"
    # This isn't a valid time with PM specified
    test_parsing ~s|"Nov 20, 2016 22:09:23 PM"|, "2016-11-20T22:09:23"
    test_parsing ~s|"Sat, 29 Sep 2018 21:36:28 -0400"|, "2018-09-30T01:36:28Z"
    test_parsing ~s|"September 28, 2016"|, "2016-09-28T00:00:00"
    test_parsing "Sun Jan 08 2017 04:28:42 GMT+0000 (UTC)", "2017-01-08T04:28:42Z"
    test_parsing "Sunday 01 January 2017 09:22:46 AM", "2017-01-01T09:22:46"
    test_parsing "Sunday 01 January 2017 10:11:02 PM", "2017-01-01T22:11:02"
    test_parsing "Thu Aug 09 2018 17:13:43 GMT+0000 (UTC)", "2018-08-09T17:13:43Z"
    test_parsing "Thu Feb 08 00:24:33 2018", "2018-02-08T00:24:33"
    test_parsing "Thu Jul  5 12:19:56 2018", "2018-07-05T12:19:56"
    test_parsing "Tue Jul 31 06:44:39 2018", "2018-07-31T06:44:39"
    test_parsing "Thursday 30 August 2018 11:31:18 AM", "2018-08-30T11:31:18"
    test_parsing "Tuesday 11 July 2017 1:43:46 PM", "2017-07-11T13:43:46"
    test_parsing ~s|"Tuesday, November 29, 2016"|, "2016-11-29T00:00:00"
    test_parsing "jul-10-18", "2018-07-10T00:00:00"
  end

  describe "parse/1 - MDY" do
    test_parsing "02/06/2019", ~N[2019-02-06 00:00:00]
    test_parsing "1/9/34", ~N[2034-01-09 00:00:00]
    test_parsing "1/9/2034", ~N[2034-01-09 00:00:00]
    test_parsing "01/09/2034", ~N[2034-01-09 00:00:00]
    test_parsing "9/4/2018 0:00", ~N[2018-09-04 00:00:00]
    test_parsing "9/1/2018 10:26", ~N[2018-09-01 10:26:00]
    test_parsing "1/13/2019", ~N[2019-01-13 00:00:00]
    test_parsing ~s|""=\""9/5/2018\"""|, ~N[2018-09-05 00:00:00]
    test_parsing "1/13/19", ~N[2019-01-13 00:00:00]
    test_parsing "1/15/2019 3:06", ~N[2019-01-15 03:06:00]
    test_parsing "4/24/2019 0:00:00", ~N[2019-04-24 00:00:00]
    test_parsing "5/2/2019 0:00:00", ~N[2019-05-02 00:00:00]
    test_parsing "5/31/2019 12:00:00 AM", ~N[2019-05-31 12:00:00]
    test_parsing "5/2/2019 12:00:00 AM", ~N[2019-05-02 12:00:00]
  end

  describe "parse/1 - DMY" do
    test_parsing "23-05-2019 @ 10:01", ~N[2019-05-23 10:01:00]
    test_parsing "9-Feb-18", ~N[2018-02-09 00:00:00]
    test_parsing "9-2-32", ~N[2032-02-09 00:00:00]
  end

  describe "parse/1 - YMD" do
    test_parsing "2019-05-16+04:00", ~N[2019-05-16 04:00:00]
    test_parsing "34-1-13", ~N[2034-01-13 00:00:00]
    test_parsing "2034-1-9", ~N[2034-01-09 00:00:00]
    test_parsing "2034-01-13", ~N[2034-01-13 00:00:00]
    test_parsing "2017-11-04 15:20:47 UTC", DateTime.from_naive!(~N[2017-11-04 15:20:47Z], "Etc/UTC")
    test_parsing "2017-11-04 15:20:47 EDT", DateTime.from_naive!(~N[2017-11-04 19:20:47Z], "Etc/UTC")
    test_parsing "2017-11-04 15:20:47 EST", DateTime.from_naive!(~N[2017-11-04 20:20:47Z], "Etc/UTC")
    test_parsing "2017-11-04 15:20:47-0500", DateTime.from_naive!(~N[2017-11-04 20:20:47Z], "Etc/UTC")
    test_parsing "2017-11-04 15:20:47+0500", DateTime.from_naive!(~N[2017-11-04 10:20:47Z], "Etc/UTC")
    test_parsing "2017-11-04 15:20:47+0000", DateTime.from_naive!(~N[2017-11-04 15:20:47Z], "Etc/UTC")
    test_parsing "2019-05-20 10:00:00PST", DateTime.from_naive!(~N[2019-05-20 17:00:00Z], "Etc/UTC")
  end

  describe "parse/1 - vocal" do
    test_parsing "Sunday 01 January 2017 10:11:02 PM", ~N[2017-01-01 22:11:02]
    test_parsing "Sunday, 01 January 2017 10:11:02 PM", ~N[2017-01-01 22:11:02]
    test_parsing "Sun, 01 January 2017 10:11:02 PM", ~N[2017-01-01 22:11:02]
    test_parsing "Sun 01 January 2017 10:11:02 PM", ~N[2017-01-01 22:11:02]
    test_parsing "November 29, 2016", ~N[2016-11-29 00:00:00]
    test_parsing "May 30, 2019 4:31:09 AM PDT", DateTime.from_naive!(~N[2019-05-30 11:31:09], "Etc/UTC")
    test_parsing "Sep-19-16", ~N[2016-09-19 00:00:00]
    test_parsing "Oct 5, 2018 6:16:56 PM PDT", DateTime.from_naive!(~N[2018-10-06 01:16:56Z], "Etc/UTC")
    test_parsing "19 September 2018 08:15:22 AM", ~N[2018-09-19 08:15:22]
    test_parsing "19 September 18 2:33:08 PM", ~N[2018-09-19 14:33:08]
    test_parsing "11 July 2017 1:43:46 PM", ~N[2017-07-11 13:43:46]
  end

  describe "parse_time/1" do
    test_time_parsing "00:00.0", ~T[00:00:00]
    test_time_parsing "07:09.3", ~T[07:09:00]
    test_time_parsing "08:53.0", ~T[08:53:00]
    test_time_parsing "10:13.7", ~T[10:13:00]
  end

  describe "errors" do
    test "returns an error when not recognized" do
      assert DateTimeParser.parse(nil) == {:error, "Could not parse nil"}
    end
  end
end

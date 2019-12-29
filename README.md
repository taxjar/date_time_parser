# DateTimeParser

[![Hex.pm Version](http://img.shields.io/hexpm/v/date_time_parser.svg)](https://hex.pm/packages/date_time_parser)
[![Hex docs](http://img.shields.io/badge/hex.pm-docs-blue.svg?style=flat)](https://hexdocs.pm/date_time_parser)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE.md)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v1.4%20adopted-ff69b4.svg)](./CODE_OF_CONDUCT.md)

DateTimeParser is a tokenizer for strings that attempts to parse into a
DateTime, NaiveDateTime if timezone is not determined, Date, or Time.

You're currently looking at the master branch. [Check out the docs for the latest
published version.](https://hexdocs.pm/date_time_parser)

## Documentation

The biggest ambiguity between datetime formats is whether it's `ymd` (year month
day), `mdy` (month day year), or `dmy` (day month year); this is resolved by
checking if there are slashes or dashes. If slashes, then it will try `dmy`
first. All other cases will use the international format `ymd`. Sometimes, if
the conditions are right, it can even parse `dmy` with dashes if the month is a
vocal month (eg, `"Jan"`).

If the string consists of only numbers, then we will try two other parsers
depending on the number of digits: [Epoch] or [Serial]. Otherwise, we'll try the
tokenizer.

If the string is 10-11 digits with optional precision, then we'll try to parse
it as a Unix [Epoch] timestamp.

If the string is 1-5 digits with optional precision, then we'll try to parse it
as a [Serial] timestamp (spreadsheet time) treating 1899-12-31 as 1. This will
cause Excel-produced dates from 1900-01-01 until 1900-03-01 to be incorrect, as
they really are.

|digits|parser|range|notes|
|---|----|---|---|
|1-5|Serial|low = `1900-01-01`, high = `2173-10-15`. Negative numbers go to `1626-03-17`|Floats indicate time. Integers do not.|
|6-9|Tokenizer|any|This allows for "20190429" to be parsed as `2019-04-29`|
|10-11|Epoch|low = `1976-03-03T09:46:40`, high = `5138-11-16 09:46:39`|If padded with 0s, then it can capture entire range. Negative numbers not yet supported|
|else|Tokenizer|any| |

[Epoch]: https://en.wikipedia.org/wiki/Unix_time
[Serial]: https://support.office.com/en-us/article/date-systems-in-excel-e7fe7167-48a9-4b96-bb53-5612a800b487

## Required reading

* [Elixir DateTime docs](https://hexdocs.pm/elixir/DateTime.html)
* [Elixir NaiveDateTime docs](https://hexdocs.pm/elixir/NaiveDateTime.html)
* [Elixir Date docs](https://hexdocs.pm/elixir/Date.html)
* [Elixir Time docs](https://hexdocs.pm/elixir/Time.html)
* [Elixir Calendar docs](https://hexdocs.pm/elixir/Calendar.html)
* [How to store future timestamps](./pages/Future-UTC-DateTime.md)
  * tldr: rules change, so don't convert to UTC too early. The future might
      change the timezone conversion rules.

## Examples

```elixir
iex> DateTimeParser.parse("19 September 2018 08:15:22 AM")
{:ok, ~N[2018-09-19 08:15:22]}

iex> DateTimeParser.parse_datetime("19 September 2018 08:15:22 AM")
{:ok, ~N[2018-09-19 08:15:22]}

iex> DateTimeParser.parse_datetime("2034-01-13", assume_time: true)
{:ok, ~N[2034-01-13 00:00:00]}

iex> DateTimeParser.parse_datetime("2034-01-13", assume_time: ~T[06:00:00])
{:ok, ~N[2034-01-13 06:00:00]}

iex> DateTimeParser.parse("invalid date 10:30pm")
{:ok, ~T[22:30:00]}

iex> DateTimeParser.parse("2019-03-11T99:99:99")
{:ok, ~D[2019-03-11]}

iex> DateTimeParser.parse("2019-03-11T10:30:00pm UNK")
{:ok, ~N[2019-03-11T22:30:00]}

iex> DateTimeParser.parse("2019-03-11T22:30:00.234+00:00")
{:ok, ~U[2019-03-11T22:30:00.234Z]}

iex> DateTimeParser.parse_date("2034-01-13")
{:ok, ~D[2034-01-13]}

iex> DateTimeParser.parse_date("01/01/2017")
{:ok, ~D[2017-01-01]}

iex> DateTimeParser.parse_datetime("1564154204")
{:ok, ~U[2019-07-26T15:16:44Z]}

iex> DateTimeParser.parse_datetime("41261.6013888889")
{:ok, ~N[2012-12-18T14:26:00]}

iex> DateTimeParser.parse_date("44262")
{:ok, ~D[2021-03-07]}
# This is a serial number date, commonly found in spreadsheets, eg: `=VALUE("03/07/2021")`

iex> DateTimeParser.parse_datetime("1/1/18 3:24 PM")
{:ok, ~N[2018-01-01T15:24:00]}

iex> DateTimeParser.parse_datetime("1/1/18 3:24 PM", assume_utc: true)
{:ok, ~U[2018-01-01T15:24:00Z]}

iex> DateTimeParser.parse_datetime(~s|"Mar 28, 2018 7:39:53 AM PDT"|, to_utc: true)
{:ok, ~U[2018-03-28T14:39:53Z]}

iex> {:ok, datetime} = DateTimeParser.parse_datetime(~s|"Mar 1, 2018 7:39:53 AM PST"|)
iex> datetime
#DateTime<2018-03-01 07:39:53-08:00 PST PST8PDT>

iex> DateTimeParser.parse_datetime(~s|"Mar 1, 2018 7:39:53 AM PST"|, to_utc: true)
{:ok, DateTime.from_naive!(~N[2018-03-01T15:39:53Z], "Etc/UTC")}

iex> {:ok, datetime} = DateTimeParser.parse_datetime(~s|"Mar 28, 2018 7:39:53 AM PDT"|)
iex> datetime
#DateTime<2018-03-28 07:39:53-07:00 PDT PST8PDT>

iex> DateTimeParser.parse_time("10:13pm")
{:ok, ~T[22:13:00]}

iex> DateTimeParser.parse_time("10:13:34")
{:ok, ~T[10:13:34]}

iex> DateTimeParser.parse_time("18:14:21.145851000000Z")
{:ok, ~T[18:14:21.145851]}

iex> DateTimeParser.parse_datetime(nil)
{:error, "Could not parse nil"}
```

[See more examples automatically generated by the tests](./EXAMPLES.md)

## Installation

Add `date_time_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:date_time_parser, "~> 1.0.0-rc.2"}
  ]
end
```

## Configuration

```elixir
# This is the default config, even if not configured.
config DateTimeParser, parsers: [:epoch, :serial, :tokenizer]

# To enable only specific parsers, include them in the :parsers key.
config DateTimeParser, parsers: [:tokenizer]

# Or in runtime, pass in the parsers in the function.
DateTimeParser.parse(mystring, parsers: [:tokenizer])
```

## Changelog

[View Changelog](./CHANGELOG.md)

## Upgrading from 0.x to 1.0

* If you use `parse_datetime/1`, then change to `parse_datetime/2` with the
  second argument as a keyword list to `assume_time: true` and `to_utc: true`.
  In 0.x, it would merge `~T[00:00:00]` if the time tokens could not be parsed;
  in 1.x, you have to opt into this behavior. Also in 0.x, a non-UTC timezone
  would automatically convert to UTC; in 1.x, the original timezone will be
  kept instead.
* If you use `parse_date/1`, then change to `parse_date/2` with the second
  argument as a keyword list to `assume_date: true`. In 0.x, it would merge
  `Date.utc_today()` with the found date tokens; in 1.x, you need to opt into
  this behavior.
* If you use `parse_time`, there is no breaking change but parsing has been
  improved.
* Not a breaking change, but 1.x introduces `parse/2` that will return the best
  struct from the tokens. This may influence your usage.

## Contributing

[How to contribute](./CONTRIBUTING.md)

## Special Thanks

[<img src="https://www.taxjar.com/img/lander/logo.svg" height=75 />](https://www.taxjar.com)

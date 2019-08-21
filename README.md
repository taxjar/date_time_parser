# DateTimeParser

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE.md)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v1.4%20adopted-ff69b4.svg)](./CODE_OF_CONDUCT.md)

DateTimeParser is a tokenizer for strings that attempts to parse into a
DateTime, NaiveDateTime if timezone is not determined, Date, or Time.

The biggest ambiguity between datetime formats is whether it's `ymd` (year month
day), `mdy` (month day year), or `dmy` (day month year); this is resolved by
checking if there are slashes or dashes. If slashes, then it will try `dmy`
first. All other cases will use the international format `ymd`. Sometimes, if
the conditions are right, it can even parse `dmy` with dashes if the month is a
vocal month (eg, `"Jan"`).

If the string is 10-11 digits with optional precision, then we'll try to parse
it as a Unix epoch timestamp.

If the string is 1-5 digits with optional precision, then we'll try to parse it
as a serial timestamp (spreadsheet time) treating 1899-12-31 as 1. This will
cause Excel-produced dates from 1900-01-01 until 1900-03-01 to be incorrect, as
they really are.

## Documentation

[Online Documentation](https://hexdocs.pm/date_time_parser)

## Examples


```elixir
iex> DateTimeParser.parse_datetime("19 September 2018 08:15:22 AM")
{:ok, ~N[2018-09-19 08:15:22]}

iex> DateTimeParser.parse_datetime("2034-01-13")
{:ok, ~N[2034-01-13 00:00:00]}

iex> DateTimeParser.parse_date("2034-01-13")
{:ok, ~D[2034-01-13]}

iex> DateTimeParser.parse_date("01/01/2017")
{:ok, ~D[2017-01-01]}

iex> DateTimeParser.parse_datetime("1/1/18 3:24 PM")
{:ok, ~N[2018-01-01T15:24:00]}

iex> DateTimeParser.parse_datetime("1/1/18 3:24 PM", assume_utc: true)
{:ok, ~U[2018-01-01T15:24:00Z]}
# the ~U is a DateTime sigil introduced in Elixir 1.9.0

iex> DateTimeParser.parse_datetime(~s|"Dec 1, 2018 7:39:53 AM PST"|)
{:ok, ~U[2018-12-01T14:39:53Z]}
# Notice that the date is converted to UTC by default

iex> {:ok, datetime} = DateTimeParser.parse_datetime(~s|"Dec 1, 2018 7:39:53 AM PST"|, to_utc: false)
iex> datetime
#DateTime<2018-12-01 07:39:53-07:00 PDT PST8PDT>

iex> DateTimeParser.parse_time("10:13pm")
{:ok, ~T[22:13:00]}

iex> DateTimeParser.parse_time("10:13:34")
{:ok, ~T[10:13:34]}

iex> DateTimeParser.parse_datetime(nil)
{:error, "Could not parse nil"}
```

[See more examples automatically generated by the tests](./EXAMPLES.md)

## Installation

Add `date_time_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:date_time_parser, "~> 0.1.3"}
  ]
end
```

## Changelog

[View Changelog](./CHANGELOG.md)

## Contributing

[How to contribute](./CONTRIBUTING.md)

## Special Thanks

[<img src="https://www.taxjar.com/img/lander/logo.svg" height=75 />](https://www.taxjar.com)

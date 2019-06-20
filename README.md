# DateTimeParser

DateTimeParser is a tokenizer for strings that attempts to parse into a
DateTime, NaiveDateTime if timezone is not determined, Date, or Time.

The biggest ambiguity between datetime formats is whether it's `ymd` (year month
day), `mdy` (month day year), or `dmy` (day month year); this is resolved by
checking if there are slashes or dashes. If slashes, then it will try `dmy`
first. All other cases will use the international format `ymd`. Sometimes, if
the conditions are right, it can even parse `dmy` with dashes if the month is a
vocal month (eg, `"Jan"`).

## Examples

```elixir
DateTimeParser.parse_datetime("19 September 2018 08:15:22 AM")
#=> {:ok, ~N[2018-09-19 08:15:22]}

DateTimeParser.parse_datetime("2034-01-13")
#=> {:ok, ~N[2034-01-13 00:00:00]}

DateTimeParser.parse_date("2034-01-13")
#=> {:ok, ~D[2034-01-13]}

DateTimeParser.parse_date("01/01/2017")
#=> {:ok, ~D[2017-01-01]}

DateTimeParser.parse_datetime("1/1/18 3:24 PM")
#=> {:ok, ~N[2018-01-01T15:24:00]}

DateTimeParser.parse_datetime(~s|"Dec 1, 2018 7:39:53 AM PST"|)
#=> {:ok, ~U[2018-12-01T14:39:53Z]}
# Notice that the date is converted to UTC

# TODO:
DateTimeParser.parse_datetime("Dec 1, 2018 7:39:53 AM PST", to_utc: false)
```

## Installation

Add `date_time_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:date_time_parser, "~> 0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/date_time_parser](https://hexdocs.pm/date_time_parser).

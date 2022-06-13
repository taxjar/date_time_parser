# DateTimeParser Playground

## Installation

Install DateTimeParser in your project

```elixir
Mix.install([:date_time_parser])
```

## Usage

Use DateTimeParser to parse strings into DateTime, NaiveDateTime, Date, or Time
structs. For example:

```elixir
[
  DateTimeParser.parse_datetime("2021-11-09T10:30:00Z"),
  DateTimeParser.parse_datetime("2021-11-09T10:30:00"),
  DateTimeParser.parse_date("2021-11-09T10:30:00Z"),
  DateTimeParser.parse_time("2021-11-09T10:30:00Z"),
  DateTimeParser.parse("2021-32-32T10:30:00Z"),
  DateTimeParser.parse("2021-11-09T10:30:00Z")
]
```

or use the bang functions:

```elixir
[
  DateTimeParser.parse_datetime!("2021-11-09T10:30:00Z"),
  DateTimeParser.parse_datetime!("2021-11-09T10:30:00"),
  DateTimeParser.parse_date!("2021-11-09T10:30:00Z"),
  DateTimeParser.parse_time!("2021-11-09T10:30:00Z"),
  DateTimeParser.parse!("2021-32-32T10:30:00Z"),
  DateTimeParser.parse!("2021-11-09T10:30:00Z")
]
```

Errors sometimes occur when it can't parse the input:

```elixir
[
  DateTimeParser.parse("wat"),
  DateTimeParser.parse(123),
  DateTimeParser.parse([:foo])
]
```

## Options

You can configure some convenient options as well, for example to automatically
convert to UTC or to assume a time when not present.

```elixir
[
  DateTimeParser.parse("12:30PM", assume_date: Date.utc_today()),
  DateTimeParser.parse("2022-01-01", assume_time: ~T[12:43:00]),
  DateTimeParser.parse("2022-01-01T15:30 EST", to_utc: true),
  DateTimeParser.parse("2022-01-01T15:30 EST", to_utc: false),
  # Excel time
  DateTimeParser.parse("30134"),
  # old Mac Excel spreadsheet time
  DateTimeParser.parse("30134.4321", use_1904_date_system: true)
]
```

## Examples

|**Input**|**Output (ISO 8601)**|**Method**|**Options**|
|:-------:|:-------------------:|:--------:|:---------:|

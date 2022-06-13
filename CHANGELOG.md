# Changelog

## 1.1.4

- Switch to pre-compiled combinators so that NimbleParsec is not needed during
  compilation-- why have everyone else compile this when we can compile it
  before publishing?
- Update examples to be a Livebook

## 1.1.3

- Stricter time parsing by requiring time separators. For example, `949` used to
  be parsed as `09:49:00`, but is now considered not valid. This is to help
  decrease false positives of nonsensical times such as `25:00 am` (incorrectly
  parsed as `02:05:00`). Thanks @fcapovilla (PR #46)

## 1.1.2

- Correct handling of 12:xx:xx AM timestamps (12hr). These were incorrectly
    parsed as 12:xx:xx (24hr) timestamps when they should have been 00:xx:xx
    (24hr) timestamps.

- Lock Timex to >= 3.2.1 and <= 3.7.2 to avoid timezone conversion issues when
  using `to_utc: true`. Looks like there are some breaking changes (for us)

## 1.1.1

- Adjust tokenizer to prefer month/day before of day/month when those are the
    only found tokens. Thanks @mwean raising the issue.

## 1.1.0

- Add option `use_1904_date_system` for the serial parser. It defaults to
    `false`. Most spreadsheet applications use the 1900 date system, but
    Microsoft Excel on Macintosh in particular used the 1904 date system
    [@fcapovilla].

## 1.0.0

### Breaking

- Change `parse_datetime` to no longer assume time. Previously, it
    would assume `00:00:00` if it could not be parsed. This is replaced with an
    opt-in option `assume_time`. See next point. If you relied on this, to
    upgrade add the option; eg: `DateTimeParser.parse_datetime(string,
    assume_time: true)`
- Change `parse_datetime` to no longer convert DateTime to UTC
    timezone. If you relied on this, to upgrade add the option; eg:
    `DateTimeParser.parse_datetime(string, to_utc: true)`
- Change `parse_date` to no longer assume a date. Previously, it
    would assume the current date, and replace the found information from the
    string. This is replaced with an opt-in option of `assume_date`. If you
    relied on this, to upgrade add the option; eg:
    `DateTimeParser.parse_date(string, assume_date: true)`

### Bugs

- Fix a UTC conversion bug between Daylight/Standard time (#20). If you're
    using an earlier version and converting to UTC, please upgrade to >=
    1.0.0-rc2 immediately.
- Fix an epoch subsecond parsing bug (#16) (thanks @tmr08c)
- Updated for compatibility with Elixir 1.10.0

### Features

- Add `parse/2` that will respond with the best match. This function accepts all
    options introduced below.
- Change `parse_datetime/1` to `parse_datetime/2` to accept options:
  - `assume_time: true | %Time{} | false` with the default of false.
- Change `parse_date/1` to `parse_date/2` to accept options:
  - `assume_date: true | %Date{} | false` with the default of false.
- Add support for parsing negative epoch times. (#24) (thanks @tmr08c)
- Add bang variants, `parse!/2`, `parse_datetime!/2`, `parse_time!/2`, and
    `parse_date!/2`
- Added `parsers: []` option to add or disable parsers. This is helpful if you
    are don't want to consider Serial or Epoch timestamps.

## 0.2.0

- Add Serial time support

## 0.1.4

- Refactor
- Support subsecond parsing to 24 digits (yoctoseconds) [thanks @myfreeweb]

## 0.1.3

- Support parsing Unix epoch times from strings
- Fix microsecond parsing

## 0.1.2

- Validate days of month. Previously it would allow invalid days such as Feb 30.
  Now it will check if the year is a leap year and allow up to 29, and otherwise
  28 for Feb. It will also reject day 31 on months without 31 days.

## 0.1.1

- Fix PM 12-hr conversion. The bug would convert 12:34PM to 24:34 which is
  not valid

## 0.1.0

- Add DateTimeParser.parse_datetime/2
- Add DateTimeParser.parse_date/1
- Add DateTimeParser.parse_time/1

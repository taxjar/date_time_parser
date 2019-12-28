# Changelog

## 1.0.0

- Add `parse/2` that will respond with the best match. This function accepts all
    options introduced below.
- Change `parse_datetime` to accept options:
  - `assume_time: true | %Time{} | false` with the default of false.
- **BREAKING** Change `parse_datetime` to no longer assume time. Previously, it
    would assume `00:00:00` if it could not be parsed. This is replaced with an
    opt-in option `assume_time`. See next point. If you relied on this, to
    upgrade add the option; eg: `DateTimeParser.parse_datetime(string,
    assume_time: true)`
- **BREAKING** Change `parse_datetime` to no longer convert DateTime to UTC
    timezone. If you relied on this, to upgrade add the option; eg:
    `DateTimeParser.parse_datetime(string, to_utc: true)`
- Change `parse_date` to accept options:
  - `assume_date: true | %Date{} | false` with the default of false.
- **BREAKING** Change `parse_date` to no longer assume a date. Previously, it
    would assume the current date, and replace the found information from the
    string. This is replaced with an opt-in option of `assume_date`. See next
    point. If you relied on this, to upgrade add the option; eg:
    `DateTimeParser.parse_date(string, assume_date: true)`
- Fixed a UTC conversion issue between Daylight/Standard time (#20)
- Added `parsers: []` option to disable parsers. This is helpful if you are
    don't want to consider Serial or Epoch timestamps.

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

# Changelog

## 0.2.0

- Support parsing Serial timestamps, commonly found in spreadsheets.

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

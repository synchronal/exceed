# Change log

## Unreleased

- Handle nils and atoms when writing cells.
- Drop support for Elixir 1.15.

## 0.3.1

- Update and organize documentation.

## 0.3.0

- Introduce the `Exceed.Worksheet.Cell` protocol for converting data
  to XmlStream fragments that can be written to a spreadsheet's XML.
- Date and DateTime cells used default formatting rules that may be
  parsed back into Dates and DateTimes.

## 0.2.0

- Dates and DateTimes have default formatting rules applied.
- Dates and DateTimes are converted to floats in Excel epoch time.

## 0.1.0

- Initial release

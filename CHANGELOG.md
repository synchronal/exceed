# Change log

## Unreleased

- Introduce the `Exceed.Worksheet.Cell` protocol for converting data
  to XmlStream fragments that can be written to a spreadsheet's XML.
- Date and DateTime cells used default formatting rules that may be
  parsed back into Dates and DateTimes.

## 0.2.0

- Dates and DateTimes have default formatting rules applied.
- Dates and DateTimes are converted to floats in Excel epoch time.

## 0.1.0

- Initial release

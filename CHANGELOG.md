# Change log

## Unreleased

## 0.6.1

- Add documentation for streaming Excel files from Phoenix controllers.

## 0.6.0

- `Exceed.stream!` accepts a `buffer` option, which defaults to `true` and disables buffering when set to `false`,
  which may be more performant in certain situations.

## 0.5.0

- Handle booleans with `t="b"`.

## 0.4.0

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

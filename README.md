# Exceed

`Exceed` is a high-level stream-oriented library for generating Excel files,
useful when generating spreadsheets from data sets large enough that they may
exceed available memory—or the available memory that one wants to dedicate to
building spreadsheets.

## Installation

``` elixir
def deps do
  [
    {:exceed, "~> 0.6"}
  ]
end
```

## Why a duck?

XLSX files are zip files containing numerous XML files following
[`SpreadsheetML`](https://learn.microsoft.com/en-us/office/open-xml/spreadsheet/structure-of-a-spreadsheetml-document?tabs=cs)
OpenXML schemas. [`High-level libraries`](https://hex.pm/packages/elixlsx) already
exist to generate XLSX files from Elixir, but do not handle streams—all
content to be written to a spreadsheet must be held in memory until the
spreadsheet is fully written.

[`Low-level libraries`](https://hex.pm/packages/xlsx_stream) already exist to
generate XLSX files from streams, but are so low level that one must know all
the ins and outs of SpreasheetML, including positional ordering of files, tags,
and attributes.

We wanted a library that hides the complexity of streaming to XML to zlib,
and hides the complexity of OOXML.


## Usage

XLSX streams are generated by initializing a workbook (with a creator name),
adding worksheets, and then converting that to a stream.

``` elixir
stream =
  Exceed.Workbook.new("Creator Name")
  |> Exceed.Workbook.add_worksheet(
    Exceed.Worksheet.new("Sheet Name", ["Heading 1", "Heading 2"],
      [["Row 1 Cell 1", "Row 1 Cell 2"], ["Row 2 Cell 1", "Row 2 Cell 2"]])
  )
  |> Exceed.stream!()

stream
|> Stream.into(File.stream!("/tmp/workbook.xslx"))
|> Stream.run()
```

Worksheets may be initialized with lists of lists, or they may be initialized
with a stream of data that maps to a list of cells.

``` elixir
rows =
  Stream.unfold(1, fn
    10_001 -> nil
    row_count -> {["Row #{row_count} Cell 1", "Row #{row_count} Cell 2"], row_count + 1}
  end)

Exceed.Worksheet.new("Sheet Name", ["Heading 1", "Heading 2"], rows)
```

## Alternatives & References

This library is inspired by and learns from other great libraries. One might
choose to use one of those in place of `Exceed`:

- [`elixlsx`](https://hex.pm/packages/elixlsx) - Provides fine-grained control
  over cells, but is not stream-oriented and thus requires that all source data
  and rows be retained in memory until the entire workbook is written.
- [`xlsx_stream`](https://hex.pm/packages/xlsx_stream) - Provides low-level
  constructs that may be combined to make an Excel file. Works nicely with
  streams. Requires that one know all the ins and outs of
  [`SpreadsheetML`](https://learn.microsoft.com/en-us/office/open-xml/spreadsheet/structure-of-a-spreadsheetml-document?tabs=cs)
  in order to make a valid file that Excel can parse.

## Contributing

This library uses [`medic`](https://github.com/synchronal/medic-rs) for its
development workflow.

``` shell
brew bundle

bin/dev/doctor
bin/dev/test
bin/dev/audit
bin/dev/update
bin/dev/shipit
```

If one does not want to install extra tooling but wishes to contribute code
fixes, new features, or documentation, please verify that code is formatted
with the versions of Elixir and Erlang specified in `.tool-versions`, passes
all tests, and passes strict credo and dialyzer.

## Benchmarks

At time of writing, benchmarks indicate that Exceed performs at 30% to 40% the
speed of non-streaming libraries such as Elixlsx. Ideas and PRs to improve the
performance of file generation are very welcome!

``` shell
# 10 columns, 100_000 rows
MIX_ENV=benchmark mix run -r benchmark/exceed.exs -e "Benchmark.run()"
# 20 columns, 1_000_000 rows
MIX_ENV=benchmark mix run -r benchmark/exceed.exs -e "Benchmark.run([], 20, 1_000_000)"
# pass options to `Exceed.File.file/3`
MIX_ENV=benchmark mix run -r benchmark/exceed.exs -e "Benchmark.run([buffer: false], 20, 1_000_000)"

# 10 columns, 100_000 rows
MIX_ENV=benchmark mix run -r benchmark/elixlsx.exs -e "Benchmark.run()"
# 20 columns, 1_000_000 rows
MIX_ENV=benchmark mix run -r benchmark/elixlsx.exs -e "Benchmark.run([], 20, 1_000_000)"
```


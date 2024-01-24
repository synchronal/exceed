defmodule Exceed.Util.Guards do
  @moduledoc false

  defguard is_valid_year?(year) when year >= 1900
end

defmodule Exceed.Util do
  # @related [tests](test/exceed/util_test.exs)

  @moduledoc "Helpers for converting Elixir data formats to Excel."
  import Exceed.Util.Guards

  @type erl_datetime_t() :: {
          {pos_integer(), pos_integer(), pos_integer()},
          {non_neg_integer(), non_neg_integer(), non_neg_integer()}
        }

  @excel_epoch {{1899, 12, 30}, {0, 0, 0}}
  @secs_per_day 86_400

  @doc """
  Converts a `Date`, `DateTime`, or `NaiveDateTime` to a float representing days
  since 1900, correcting for the Lotus 123 bug (Excel treats 1900 as a leap
  year).

  ## Examples

  ``` elixir
  ```
  """
  @spec to_excel_datetime(erl_datetime_t() | Date.t() | DateTime.t() | NaiveDateTime.t()) :: float()
  def to_excel_datetime({{1900, mm, dd}, {h, m, s}})
      when mm in [1, 2] do
    in_seconds = :calendar.datetime_to_gregorian_seconds({{1900, mm, dd}, {h, m, s}})
    excel_epoch = :calendar.datetime_to_gregorian_seconds(@excel_epoch)

    timestamp = (in_seconds - excel_epoch) / @secs_per_day
    timestamp - 1
  end

  def to_excel_datetime({{yy, mm, dd}, {h, m, s}}) when is_valid_year?(yy) do
    in_seconds = :calendar.datetime_to_gregorian_seconds({{yy, mm, dd}, {h, m, s}})
    excel_epoch = :calendar.datetime_to_gregorian_seconds(@excel_epoch)

    (in_seconds - excel_epoch) / @secs_per_day
  end

  def to_excel_datetime(%DateTime{year: yy, month: mm, day: dd, hour: h, minute: m, second: s, time_zone: "Etc/UTC"})
      when is_valid_year?(yy),
      do: to_excel_datetime({{yy, mm, dd}, {h, m, s}})

  def to_excel_datetime(%DateTime{time_zone: "Etc/UTC"} = datetime),
    do: DateTime.to_iso8601(datetime)

  def to_excel_datetime(%NaiveDateTime{year: yy, month: mm, day: dd, hour: h, minute: m, second: s})
      when is_valid_year?(yy),
      do: to_excel_datetime({{yy, mm, dd}, {h, m, s}})

  def to_excel_datetime(%NaiveDateTime{} = datetime),
    do: NaiveDateTime.to_iso8601(datetime)

  def to_excel_datetime(%Date{year: yy, month: mm, day: dd}) when is_valid_year?(yy),
    do: to_excel_datetime({{yy, mm, dd}, {0, 0, 0}})

  def to_excel_datetime(%Date{} = datetime),
    do: Date.to_iso8601(datetime)
end

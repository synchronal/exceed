# Phoenix Integration

Given a Phoenix application, Excel files streamed via Exceed may be downloaded from controllers.
This requires that the `conn` be configured as a chunked, and then each chunk of the stream be
reduced into it.

## Examples

``` elixir
defmodule Web.ExcelController do
  use Web, :controller

  def download(conn, _params) do
    conn =
      conn
      |> put_resp_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      |> put_resp_header("content-disposition", "attachment; filename=file.xlsx")
      |> send_chunked(:ok)

    for excel_chunk <- excel_stream(), reduce: conn do
      conn ->
        case chunk(conn, excel_chunk) do
          {:ok, conn} -> {:cont, conn}
          {:error, :closed} -> {:halt, conn}
        end
    end
  end

  # # #

  defp excel_stream do
    Exceed.Workbook.new("Creator Name")
    |> Exceed.Workbook.add_worksheet(
      Exceed.Worksheet.new("Sheet Name", ["Heading 1", "Heading 2"],
        [["Row 1 Cell 1", "Row 1 Cell 2"], ["Row 2 Cell 1", "Row 2 Cell 2"]])
    )
    |> Exceed.stream!()
  end
end
```

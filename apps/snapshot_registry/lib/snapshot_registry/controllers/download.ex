defmodule Staxx.SnapshotRegistry.Controllers.Download do
  @moduledoc """
  Plug controller for download a file in parts
  """

  use Plug.Builder

  def init(opts), do: opts

  @doc """
  Handler for POST /download endpoint
  """
  def call(conn, _opts) do
    file_path = build_path()

    %File.Stat{type: :regular, size: file_size} = File.stat!(file_path)

    case parse_range_header(conn) do
      :no_range ->
        send_success(conn, 200, file_path)

      {req_start, req_end} when req_start >= 0 and req_end <= file_size and req_start < req_end ->
        send_success(conn, 206, file_path, req_start, req_end - req_start)

      _ ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(416, "416 Range Not Satisfiable")
    end
  end

  defp send_success(conn, status, file_path, req_start \\ 0, length \\ :all) do
    conn
    |> put_resp_header("content-type", "application/octet-stream")
    |> put_resp_header("accept-ranges", "bytes")
    |> send_file(status, file_path, req_start, length)
  end

  # Build path of file for download
  # now using fixture file because snapshot files are not fully ready to be used
  # This is tmp solution to prove snapshot registry work.
  # TODO: rework to download snapshot files
  defp build_path() do
    :snapshot_registry
    |> Application.get_env(:snapshot_fixtures_path)
    |> Path.expand()
    |> Path.join("text.txt")
  end

  # Fetch range data from request header
  defp parse_range_header(conn) do
    with [str] <- get_req_header(conn, "range"),
         [_, offset, limit] <- Regex.run(~r/bytes=(\d+)?-(\d+)?/, str),
         {parsed_offset, ""} <- Integer.parse(offset),
         {parsed_limit, ""} <- Integer.parse(limit) do
      {parsed_offset, parsed_limit}
    else
      [] ->
        :no_range

      _ ->
        :error
    end
  end
end

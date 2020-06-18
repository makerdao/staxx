defmodule Staxx.Transport.FileFactory do
  @moduledoc """
  FileFactory provides functions to easily create large files for testing purposes.
  Uses `:transport, :file_factory_dir` config to determine test files directory. By default directory is `/tmp`.
  """
  alias Staxx.Transport.FileUtils

  @large_file_size 1_073_741_824
  @block_size 1024

  @doc """
  Creates 1 Gb size file and returns path to created file.
  """
  @spec create_large_file :: {:error, any} | {:ok, binary}
  def create_large_file(), do: create_file(@large_file_size)

  @doc """
  Creates file with given size in bytes and returns path to it.
  Uses `dd` command to create files. Block size is 1024. Uses `/dev/zero` to fill file.
  """
  @spec create_file(pos_integer()) :: {:ok, Path.t()} | {:error, term()}
  def create_file(size_bytes) when is_integer(size_bytes) and size_bytes > 0 do
    filepath =
      Application.get_env(:transport, :file_factory_dir, "/tmp")
      |> Path.join(FileUtils.random_filename())

    args = [
      input_source_arg(),
      output_arg(filepath),
      count_arg(size_bytes, @block_size),
      block_size_arg(@block_size)
    ]

    System.cmd("dd", args)
    |> case do
      {_response, 0} -> {:ok, filepath}
      {response, _} -> {:error, response}
    end
  end

  defp input_source_arg(), do: "if=/dev/zero"
  defp output_arg(filepath), do: "of=" <> filepath

  defp count_arg(size_bytes, block_size),
    do: "count=" <> (div(size_bytes, block_size) |> Integer.to_string())

  defp block_size_arg(block_size), do: "bs=" <> (block_size |> Integer.to_string())
end

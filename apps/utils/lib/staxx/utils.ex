defmodule Staxx.Utils do
  @moduledoc """
  Base projectwise utilities
  """

  @doc """
  Tries to create directory `path`.
  """
  @spec mkdir_p(binary) :: :ok | {:error, term}
  def mkdir_p(path) do
    path
    |> File.mkdir_p()
    |> case do
      :ok ->
        File.chmod(path, Application.get_env(:utils, :dir_chmod, 0o644))
        :ok

      err ->
        err
    end
  end

  @doc """
  Writes `content` to the file `path`.
  """
  @spec file_write(Path.t(), iodata(), [File.mode()]) :: :ok | {:error, term}
  def file_write(path, content, modes \\ []) do
    path
    |> File.write(content, modes)
    |> case do
      :ok ->
        File.chmod(path, Application.get_env(:utils, :file_chmod, 0o644))
        :ok

      err ->
        err
    end
  end
end

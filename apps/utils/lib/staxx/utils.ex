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

  def file_write(file, content, modes \\ []) do
    file
    |> File.write(content, modes)
    |> case do
      :ok ->
        File.chmod(file, Application.get_env(:utils, :file_chmod, 0o644))
        :ok

      err ->
        err
    end
  end
end

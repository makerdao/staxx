defmodule Staxx.Transport.FileUtils do
  @moduledoc """
  Module for file related functions.
  """

  @doc """
  Calculates MD5 hash of file by given path.
  Returns hash as `{:ok, binary}`.
  Returns `{:error, :enoent}` if there are problems with file reading.
  """
  @spec md5_for_file(binary | Path.t()) :: {:ok, binary()} | {:error, term()}
  def md5_for_file(filepath) do
    case File.exists?(filepath) do
      true ->
        {:ok,
         filepath
         |> File.stream!([], 2048)
         |> Enum.reduce(:crypto.hash_init(:md5), fn line, acc ->
           :crypto.hash_update(acc, line)
         end)
         |> :crypto.hash_final()
         |> Base.encode16()
         |> String.downcase()}

      false ->
        {:error, :enoent}
    end
  end

  @doc """
  Returns size of file via File.stat/2
  """
  @spec size_of_file(binary() | Path.t()) :: non_neg_integer()
  def size_of_file(path) do
    {:ok, %{size: size}} = File.stat(path)
    size
  end

  @doc """
  Returns randomly generated string containing numbers
  """
  @spec random_filename :: binary()
  def random_filename() do
    <<id::64>> = :crypto.strong_rand_bytes(8)
    to_string(id)
  end

  @doc """
  Returns randomly generated filepath in given directory.
  """
  @spec new_random_filepath(binary() | Path.t()) :: binary()
  def new_random_filepath(tmp_dir) do
    filename = random_filename()
    path = Path.join(tmp_dir, filename)

    if File.exists?(path) do
      new_random_filepath(tmp_dir)
    else
      path
    end
  end

  @doc """
  Appends binary data to the file by given path.
  """
  @spec append_data_to_file(binary() | Path.t(), binary()) :: :ok
  def append_data_to_file(filepath, data), do: File.write!(filepath, data, [:binary, :append])

  @doc """
  Creates file with given path.
  """
  @spec create_file(binary) :: :ok
  def create_file(filepath), do: File.touch!(filepath)

  @doc """
  Creates directory by given path if directory is not exist
  """
  @spec create_rand_dir(binary() | Path.t()) :: :ok
  def create_rand_dir(path) do
    unless File.exists?(path) do
      File.mkdir(path)
    end
  end
end

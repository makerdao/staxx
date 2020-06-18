defmodule Staxx.Transport.DataUtils do
  @moduledoc """
  Utils module to help to work with socket and data packets.
  """

  @meta_data_delimiter "<#>"

  @doc """
  Returns "ready to execute" Stream containing AUTH, META, data packets, EOF packet and execute function for each item.
  Just make it run, Forrest!
  """
  @spec send_data_stream(binary(), binary(), binary(), integer, function(), map()) ::
          Stream.t()
  def send_data_stream(
        token,
        filepath,
        md5_hash,
        content_length,
        exec_func,
        payload \\ %{}
      ) do
    chunk_size = Application.get_env(:transport, :data_packet_size_bytes, 2048)
    filename = Path.basename(filepath)

    file_stream = File.stream!(filepath, [], chunk_size)
    auth_packet_enum = [auth_packet(token)]
    meta_packet_enum = [meta_packet(filename, md5_hash, content_length, payload)]

    auth_packet_enum
    |> Stream.concat(meta_packet_enum)
    |> Stream.concat(file_stream)
    |> Stream.concat([eof_packet()])
    |> Stream.each(exec_func)
  end

  @doc """
  Parses and returns md5, content_length and filename from META packet.
  Returns `{md5, content_lenght, filename, payload}` tuple.
  """
  @spec parse_meta_packet(binary()) :: {binary(), non_neg_integer(), binary(), map()}
  def parse_meta_packet(
        <<"META", md5::binary-size(32), content_length::integer-size(64), rest::binary>>
      ) do
    [filename, payload_bin] =
      rest
      |> String.split(@meta_data_delimiter)

    payload = :erlang.binary_to_term(payload_bin, [:safe])
    {md5, content_length, filename, payload}
  end

  @doc """
  Returns binary with META header containing given filename, description, chain_type, md5 hash and content length.
  """
  @spec meta_packet(binary, binary, integer, map()) :: binary()
  def meta_packet(filename, md5, content_length, payload)
      when is_binary(filename) and is_binary(md5) and is_integer(content_length) do
    payload_bin = :erlang.term_to_binary(payload)

    <<"META", md5::binary-size(32), content_length::integer-size(64), filename::binary,
      @meta_data_delimiter, payload_bin::binary>>
  end

  @doc """
  Returns binary with EOF header.
  This packet indicates the last packet in data transfering chain.
  """
  @spec eof_packet() :: binary()
  def eof_packet(), do: <<"EOF">>

  @doc """
  Returns binary with COMPLETE header.
  This packet indicates data transfer complete successfully and hashed are match.
  """
  @spec complete_packet() :: binary()
  def complete_packet, do: <<"COMPLETE">>

  @doc """
  Returns binary with WRONG_HASH header.
  This packet indicates that transfered file hash doesn't  match hash sent in "META" packet earlier.
  """
  @spec wrong_hash_packet() :: binary()
  def wrong_hash_packet, do: <<"WRONG_HASH">>

  @doc """
  Returns binary with AUTH header and token to make authentication on server.
  """
  @spec auth_packet(binary) :: binary()
  def auth_packet(token \\ "") when is_binary(token), do: <<"AUTH", token::binary>>

  @doc """
  Returns binary with AUTH_SUCCESS or AUTH_FAILED header depending on boolean value of the parameter.
  Sent if authentication successfull or not.
  """
  @spec auth_response_packet(boolean()) :: binary()
  def auth_response_packet(true), do: <<"AUTH_SUCCESS">>
  def auth_response_packet(false), do: <<"AUTH_FAILED">>
end

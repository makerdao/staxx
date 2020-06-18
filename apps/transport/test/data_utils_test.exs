defmodule Staxx.Transport.DataUtilsTest do
  use ExUnit.Case
  alias Staxx.Transport.DataUtils

  @moduletag :data_test
  test "test of META binary packet" do
    filename = "filename"
    description = Faker.Lorem.paragraph()
    chain_type = Faker.String.base64()
    md5 = "1BC29B36F623BA82AAF6724FD3B16718"
    size = 2048
    payload = %{description: description, chain_type: chain_type}

    assert {md5, size, filename, %{description: description, chain_type: chain_type}} ==
             DataUtils.meta_packet(filename, md5, size, payload)
             |> DataUtils.parse_meta_packet()
  end

  test "test of eof, hash, complete packets" do
    assert <<"EOF">> = DataUtils.eof_packet()
    assert <<"COMPLETE">> = DataUtils.complete_packet()

    token = "SOMETOKENYESITISTOKEN"
    assert <<"AUTH", token1::binary>> = DataUtils.auth_packet(token)
    assert token == token1

    assert <<"WRONG_HASH">> = DataUtils.wrong_hash_packet()

    assert <<"AUTH_SUCCESS">> = DataUtils.auth_response_packet(true)
    assert <<"AUTH_FAILED">> = DataUtils.auth_response_packet(false)
  end
end

defmodule Staxx.Transport.TestCase do
  use ExUnit.CaseTemplate

  alias Staxx.Transport.FileFactory

  setup_all do
    server_tmp_dir = "/tmp/transfered_files"

    unless File.exists?(server_tmp_dir) do
      File.mkdir!(server_tmp_dir)
    end

    {:ok, filepath} = FileFactory.create_large_file()

    assert_timeout = Application.get_env(:ex_unit, :assert_receive_timeout)

    on_exit(fn ->
      File.rm_rf(server_tmp_dir)
      File.rm(filepath)
    end)

    {:ok,
     server_tmp_dir: server_tmp_dir,
     filepath: filepath,
     assert_timeout: assert_timeout,
     port: 2233}
  end
end

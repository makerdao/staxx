defmodule Mix.Tasks.Account.Gen.New do
  @shortdoc "Create list of new default accounts for chains"
  @moduledoc """
  Generates new deafult accounts for chains.

      mix account.gen.new

  Will drop all old accounts so be careful.
  """

  use Mix.Task

  # Executable name for `geth` EVM.
  @geth_executable "geth"

  # Path with list of accounts.
  @accounts_path "priv/presets/accounts"

  # Default password file for new account creation.
  @password_file "priv/presets/geth/account_password"

  def run(_) do
    unless System.find_executable(@geth_executable) do
      Mix.raise(
        "mix account.gen.new requires `geth` executable to be installed on your machine !"
      )
    end

    full_acc_path = Path.absname(@accounts_path)
    full_pass_file = Path.absname(@password_file)

    full_acc_path
    |> File.dir?()
    |> unless do
      Mix.raise("""
      Wrong or non existing accounts path given.
      Path given: #{full_acc_path}
      """)
    end

    full_pass_file
    |> File.exists?()
    |> unless do
      Mix.raise("""
      Wrong or non existing password file given.
      Password file path: #{full_pass_file}
      """)
    end

    if Mix.shell().yes?("All old address files will be removed. Are you sure ?") do
      regenerate(full_acc_path, full_pass_file)
    end
  end

  # Does regeneration of files
  defp regenerate(account_path, password_file) do
    Mix.shell().info("Cleaning up accounts folder...")

    account_path
    |> File.ls!()
    |> Enum.each(&remove_file(&1, account_path))

    Mix.shell().info("Generating new accounts. It might take a while...")

    1..100
    |> Enum.each(&generate_account(&1, account_path, password_file))

    Mix.shell().info("New account generated !")

    # remove `geth` folder after generation.
    remove_file("geth", account_path)
  end

  # Generate new account file using `geth` executable
  defp generate_account(index, account_path, password_file) do
    {_, 0} =
      @geth_executable
      |> System.find_executable()
      |> System.cmd(
        [
          "account",
          "new",
          "--datadir",
          account_path,
          "--keystore",
          account_path,
          "--password",
          password_file
        ],
        stderr_to_stdout: true
      )

    ProgressBar.render(index, 100)
  end

  defp remove_file(filename, path) do
    path
    |> Path.join(filename)
    |> File.rm_rf!()
  end
end

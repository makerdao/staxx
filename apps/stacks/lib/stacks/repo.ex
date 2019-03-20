defmodule Stacks.Repo do
  use Ecto.Repo,
    otp_app: :stacks,
    adapter: Ecto.Adapters.Postgres
end

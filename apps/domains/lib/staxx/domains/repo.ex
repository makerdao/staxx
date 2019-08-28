defmodule Staxx.Domains.Repo do
  use Ecto.Repo,
    otp_app: :domains,
    adapter: Ecto.Adapters.Postgres
end

defmodule Staxx.SnapshotRegistry.Repo do
  use Ecto.Repo,
    otp_app: :snapshot_registry,
    adapter: Ecto.Adapters.Postgres
end

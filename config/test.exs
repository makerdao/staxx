import Config

config :logger,
  backends: [:console],
  level: :info,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

# Configuring timeouts for receiving messages
config :ex_unit, assert_receive_timeout: 60_000

config :event_stream, disable_nats: true

config :docker, adapter: Staxx.Docker.Adapter.Mock

config :environment, stacks_dir: "#{__DIR__}/../priv/test/stacks"

config :environment,
  testchain_supervisor_module: Staxx.Environment.Test.TestchainSupervisorMock

config :store, Staxx.Store.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :store, Staxx.Store.Repo,
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  username: System.get_env("POSTGRES_USER", "postgres"),
  database: System.get_env("POSTGRES_DB", "staxx_test")

#
# Testchain
#
config :testchain, base_path: "#{__DIR__}/../.test/chains"
# DB path where all list of chain workers will be stored
config :testchain, dets_db_path: "#{__DIR__}/../.test/chains"
config :testchain, snapshot_base_path: "#{__DIR__}/../.test/chains"

config :testchain,
  internal_host: System.get_env("TESTCHAIN_INTERNAL_HOST", "localhost")

#
# Metrics
#
config :metrix, run_prometheus: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_api, Staxx.WebApiWeb.Endpoint,
  http: [port: 4002],
  server: false

#
# SnapshotRegistry configs
#

# Default path where snapshots will be stored
# Paths where snapshots will be stored
config :snapshot_registry,
  snapshot_temporary_path: "#{__DIR__}/../apps/snapshot_registry/test/files/tmp",
  snapshot_base_path: "#{__DIR__}/../apps/snapshot_registry/test/files/base",
  snapshot_fixtures_path: "#{__DIR__}/../apps/snapshot_registry/test/files/fixtures"

config :snapshot_registry, Staxx.SnapshotRegistry.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :snapshot_registry, Staxx.SnapshotRegistry.Repo,
  hostname: System.get_env("SR_POSTGRES_HOST", "localhost"),
  username: System.get_env("SR_POSTGRES_USER", "postgres"),
  database: System.get_env("SR_POSTGRES_DB", "snapshot_registry_test")

config :transport, test_files_path: "#{__DIR__}/../apps/transport/test/files"

config :web_api, test_user_email: "test@rmail.com"

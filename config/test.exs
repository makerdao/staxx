import Config

config :logger,
  backends: [:console],
  level: :error,
  compile_time_purge_matching: [
    [level_lower_than: :error]
  ]

# Configuring timeouts for receiving messages
config :ex_unit, assert_receive_timeout: 30_000

config :metrix, run_prometheus: false
config :event_stream, disable_nats: true

# config :docker, adapter: Staxx.Docker.Adapter.Mock

config :deployment_scope, stacks_dir: "#{__DIR__}/../priv/test/stacks"

config :store, Staxx.Store.Repo, pool: Ecto.Adapters.SQL.Sandbox

#
# Metrics
#
config :metrix, run_prometheus: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_api, Staxx.WebApiWeb.Endpoint,
  http: [port: 4002],
  server: false

config :store, Staxx.Store.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  database: System.get_env("POSTGRES_DB", "staxx_test")

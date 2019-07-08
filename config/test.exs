import Config

config :logger,
  backends: [:console],
  level: :warn,
  compile_time_purge_matching: [
    [level_lower_than: :warn]
  ]

config :docker, adapter: Docker.Adapter.Mock
config :stacks, stacks_dir: "/tmp/stacks"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_api, WebApiWeb.Endpoint,
  http: [port: 4002],
  server: false

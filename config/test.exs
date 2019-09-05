import Config

config :logger,
  backends: [:console],
  level: :error,
  compile_time_purge_matching: [
    [level_lower_than: :error]
  ]

config :event_stream, disable_nats: true

config :docker, adapter: Staxx.Docker.Adapter.Mock

config :deployment_scope, stacks_dir: "#{__DIR__}/../priv/test/stacks"

config :proxy, ex_chain_adapter: Staxx.Proxy.ExChain.FakeExChain
config :proxy, node_manager_adapter: Staxx.Proxy.NodeManager.FakeNodeManager

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_api, Staxx.WebApiWeb.Endpoint,
  http: [port: 4002],
  server: false

config :ex_chain,
  ganache_executable:
    System.get_env("GANACHE_EXECUTABLE") ||
      Path.expand("#{__DIR__}/../priv/presets/ganache-cli/cli.js")

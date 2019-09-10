# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

#
# Deployemnt Scope configs
#
config :deployment_scope, stacks_dir: "/tmp/stacks"

#
# Docker configs
#
config :docker, wrapper_file: Path.expand("#{__DIR__}/../apps/docker/priv/wrapper.sh")

# If this config is set to `false` `dev_mode` for starting new containers will be ignored !
# Shuold be set to `false` in cloud env.
config :docker, dev_mode_allowed: "true"

#
# Event bus app config
#
config :event_bus,
  topics: [
    :chain,
    :docker
  ]

# Nats.io configuration
config :event_stream, disable_nats: false
config :event_stream, nats: %{host: "127.0.0.1", port: 4222}
config :event_stream, nats_docker_events_topic: "Prefix.Docker.Events"

#
# Proxy application config
#
# config :proxy, replace_docker_url: true

# ExChain adapter
config :proxy, ex_chain_adapter: Staxx.Proxy.ExChain.Local
# Node manager
config :proxy, node_manager_adapter: Staxx.Proxy.NodeManager.Local

config :proxy, deployment_service_url: "http://localhost:5001/rpc"
config :proxy, deploy_chain_front_url: "host.docker.internal"
config :proxy, deployment_steps_fetch_timeout: 30_000
# DB path where all list of chain workers will be stored
config :proxy, dets_db_path: "/tmp/chains"
# Place where to upload snapshots
config :proxy, snapshot_path: "/tmp/snapshots"
# deployment timeout
config :proxy, deployment_timeout: 1_800_000
config :proxy, action_timeout: 600_000

#
# Metrics
#
config :metrix, run_prometheus: true

config :telemetry_poller, :default,
  # this is the default
  vm_measurements: :default

#
# WebAPI configs
#
# Configures the endpoint
config :web_api, Staxx.WebApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JVM+w2YiFWxOCzzCpZFhyDTygERfvFXEWMqAThkzfBnRqcsw/mskVPOJ9hCP8pcu",
  render_errors: [view: Staxx.WebApiWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Staxx.WebApi.PubSub, adapter: Phoenix.PubSub.PG2]

# Use Jason for JSON parsing in Phoenix
# config :phoenix, :json_library, Jason
config :phoenix, :json_library, Poison

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :storage, provider: Staxx.Storage.Provider.Dets
config :storage, dets_db_path: "/tmp/chains"

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

config :porcelain, driver: Porcelain.Driver.Basic

# Amount of time in ms process allowed to perform "blocking" work before supervisor will terminate it
config :ex_chain, kill_timeout: 180_000

# URL that will be placed to chain.
# It's actually outside world URL to testchain.
# For local development it should be `localhost`
# For production instance in cloud it will be changed to real DNS address.
# NOTE: you don't need protocol here (`http:// | ws://`) it will be set by evm provider
config :ex_chain, front_url: "localhost"
# config :ex_chain, front_url: "host.docker.internal"

# Default folder where all chain db's will be created, please use full path
# Note that chain id will be added as final folder.
# Example: with `config :ex_chain, base_path: "/tmp/chains"`
# Final chain path will be
# `/tmp/chains/some-id-here`
config :ex_chain, base_path: "/tmp/chains"

# Default chainId that will be assigned to chain if it was not passed
# as parameter for chain on start
config :ex_chain, default_chain_id: 999

# Default path where snapshots will be stored for chain
# chain id will be added as a target folder under this path
config :ex_chain, snapshot_base_path: "/tmp/snapshots"

# Path whre snapshots DB will be stored
config :ex_chain, snapshot_db_path: :"/tmp/db/snapshots"

# List of ports available for evm allocation
config :ex_chain, evm_port_range: 8500..8600

config :ex_chain, backend_proxy_node: :"staxx@127.0.0.1"
config :ex_chain, backend_proxy_node_reconnection_timeout: 5_000

# Default location of account password file.
# For dev env it will be in related to project root. In Docker it will be replaced with
# file from `rel/config/config.exs`
config :ex_chain,
  geth_executable: System.find_executable("geth"),
  # geth_executable: "/tmp/chains/test/go-ethereum/build/bin/geth",
  geth_vdb_executable: Path.expand("#{__DIR__}/../priv/presets/geth/geth_vdb"),
  geth_password_file: Path.expand("#{__DIR__}/../priv/presets/geth/account_password"),
  ganache_executable: Path.expand("#{__DIR__}/../priv/presets/ganache-cli/cli.js"),
  ganache_wrapper_file: Path.expand("#{__DIR__}/../priv/presets/ganache/wrapper.sh")

import_config "#{Mix.env()}.exs"

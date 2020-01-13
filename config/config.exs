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
config :deployment_scope, deployment_service_url: "http://localhost:5001/rpc"
config :deployment_scope, deployment_steps_fetch_timeout: 30_000
# DB path where all list of chain workers will be stored
config :deployment_scope, dets_db_path: "/tmp/chains"
# deployment timeout
config :deployment_scope, deployment_timeout: 1_800_000
config :deployment_scope, action_timeout: 600_000
config :deployment_scope, deployment_worker_image: "makerdao/testchain-deployment-worker:dev"

#
# Deployment scope adapters
#
config :deployment_scope, testchain_supervisor_module: Staxx.Testchain.Supervisor

#
# Docker configs
#
config :docker, wrapper_file: Path.expand("#{__DIR__}/../apps/docker/priv/wrapper.sh")

# If this config is set to `false` `dev_mode` for starting new containers will be ignored !
# Shuold be set to `false` in cloud env.
config :docker, dev_mode_allowed: "true"

# Timeout for `Staxx.Docker.run_sync/1` command
config :docker, sync_timmeout: 180_000

# Default docker adapter
config :docker, adapter: Staxx.Docker.Adapter.DockerD

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
config :event_stream, nats: %{host: "nats.local", port: 4222}
config :event_stream, nats_docker_events_topic: "Prefix.Docker.Events"

#
# Store configs
#
config :store, Staxx.Store.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: System.get_env("POSTGRES_DB", "staxx"),
  hostname: System.get_env("POSTGRES_HOST", "localhost")

config :store, ecto_repos: [Staxx.Store.Repo]

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
config :phoenix, :json_library, Jason
# config :phoenix, :json_library, Poison

# Configures Elixir's Logger
config :logger, truncate: :infinity

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# Host for chains (for deployment process)
config :testchain, host: "host.docker.internal"

# NATS.io url for deployment process
config :testchain, nats: %{host: "nats.local", port: 4222}

# Default timeout for checking testchain health
config :testchain, health_check_timeout: 30_000

# Amount of time in ms process allowed to perform "blocking" work before supervisor will terminate it
config :testchain, kill_timeout: 180_000

# URL that will be placed to chain.
# It's actually outside world URL to testchain.
# For local development it should be `localhost`
# For production instance in cloud it will be changed to real DNS address.
# NOTE: you don't need protocol here (`http:// | ws://`) it will be set by evm provider
config :testchain, front_url: "localhost"

# Default folder where all chain db's will be created, please use full path
# Note that chain id will be added as final folder.
# Example: with `config :testchain, base_path: "/tmp/chains"`
# Final chain path will be
# `/tmp/chains/some-id-here`
config :testchain, base_path: "/tmp/chains"

# DB path where all list of chain workers will be stored
config :testchain, dets_db_path: "/tmp/chains"

# Default chainId that will be assigned to chain if it was not passed
# as parameter for chain on start
config :testchain, default_chain_id: 999

# Default path where snapshots will be stored for chain
# chain id will be added as a target folder under this path
config :testchain, snapshot_base_path: "/tmp/snapshots"

# Default deployment scripts git ref
config :testchain, default_deployment_scripts_git_ref: "refs/tags/staxx-testrunner"

# Default location of account password file.
# For dev env it will be in related to project root. In Docker it will be replaced with
# file from `rel/config/config.exs`
config :testchain,
  geth_docker_image: "makerdao/geth_evm:1.8.27",
  ganache_docker_image: "makerdao/ganache_evm:6.7.0"


#
# Utils configs
#

# Default mode for newly created files
config :utils, file_chmod: 0o777
# Default mode for newly created folders
config :utils, dir_chmod: 0o777

import_config "#{Mix.env()}.exs"

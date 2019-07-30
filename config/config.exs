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
config :proxy, ex_chain_adapter: Staxx.Proxy.ExChain.Remote
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

import_config "#{Mix.env()}.exs"

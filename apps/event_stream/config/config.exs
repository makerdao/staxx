# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :event_bus,
  topics: [
    :chain,
    :docker
  ]

# Nats.io configuration
config :event_stream, nats: %{host: "127.0.0.1", port: 4222}

config :event_stream, nats_docker_events_topic: "Prefix.Docker.Events"

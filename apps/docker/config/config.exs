# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

config :docker, wrapper_file: Path.expand("#{__DIR__}/../priv/wrapper.sh")

config :docker, nats: %{host: "localhost", port: 4222}
config :docker, nats_docker_events_topic: "Prefix.Docker.Events"

#     import_config "#{Mix.env()}.exs"

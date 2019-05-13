# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :stacks,
  ecto_repos: [Stacks.Repo]

config :stacks, docker_events_topic: "Prefix.Docker.Events"

import_config "#{Mix.env()}.exs"

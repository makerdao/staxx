use Mix.Config

config :stacks, Stacks.Repo,
  database: "stacks_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :stacks, stacks_dir: "/tmp/stacks"

use Mix.Config

config :stacks, Stacks.Repo,
  database: "stacks",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :stacks, stacks_dir: "/tmp/stacks"

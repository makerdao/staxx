use Mix.Config

config :proxy, deployment_service_url: System.get_env("DEPLOYMENT_SERVICE_URL") || "http://testchain-deployment.local:5001/rpc"
config :proxy, deploy_chain_front_url: System.get_env("CHAINS_FRONT_URL") || "host.docker.internal"
config :proxy, dets_db_path: System.get_env("CHAINS_DB_PATH") || "/opt/chains"
config :proxy, deployment_steps_fetch_timeout: 30_000
config :proxy, call_oracles: System.get_env("CALL_ORACLES") != nil
config :proxy, nats: %{host: System.get_env("NATS_URL") || "nats.local", port: 4222}

config :stacks, stacks_dir: System.get_env("STACKS_DIR") || "/opt/stacks"
config :stacks, front_url: "http://localhost"

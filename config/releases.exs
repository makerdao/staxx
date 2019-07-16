import Config

config :proxy, deployment_service_url: System.fetch_env!("DEPLOYMENT_SERVICE_URL")
config :proxy, deploy_chain_front_url: System.fetch_env!("CHAINS_FRONT_URL")
config :proxy, dets_db_path: System.fetch_env!("CHAINS_DB_PATH")
config :proxy, deployment_steps_fetch_timeout: 30_000

config :event_stream, nats: %{host: System.fetch_env!("NATS_URL"), port: 4222}

config :stacks, stacks_dir: System.fetch_env!("STACKS_DIR")
config :stacks, front_url: System.fetch_env!("STACKS_FRONT_URL")

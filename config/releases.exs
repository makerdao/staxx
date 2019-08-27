import Config

config :logger, Gelfx, 
  host: System.fetch_env!("GRAYLOG_HOST")

# To set it to true, pass `DOCKER_DEV_MODE_ALLOWED=true`, all other variables will be interpritated as false
config :docker, dev_mode_allowed: System.fetch_env!("DOCKER_DEV_MODE_ALLOWED")

config :proxy, deployment_service_url: System.fetch_env!("DEPLOYMENT_SERVICE_URL")
config :proxy, deploy_chain_front_url: System.fetch_env!("CHAINS_FRONT_URL")
config :proxy, dets_db_path: System.fetch_env!("CHAINS_DB_PATH")
config :proxy, deployment_steps_fetch_timeout: 30_000

config :event_stream, nats: %{host: System.fetch_env!("NATS_URL"), port: 4222}

config :deployment_scope, stacks_dir: System.fetch_env!("STACKS_DIR")

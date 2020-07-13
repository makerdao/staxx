import Config

# To set it to true, pass `DOCKER_DEV_MODE_ALLOWED=true`, all other variables will be interpritated as false
config :docker, dev_mode_allowed: System.get_env("DOCKER_DEV_MODE_ALLOWED", "false")
# Default nats network
config :docker, nats_network: System.get_env("DOCKER_NATS_NETWORK", "container:nats.local")
# Default staxx network
config :docker, staxx_network: System.get_env("DOCKER_STAXX_NETWORK", "")

# If `IN_CONTAINER` is set - that wil be resolved to `true`
config :docker, in_container?: System.get_env("IN_CONTAINER", "") != ""

config :environment, deployment_service_url: System.fetch_env!("DEPLOYMENT_SERVICE_URL")
config :environment, deployment_steps_fetch_timeout: 30_000
config :environment, dets_db_path: System.fetch_env!("CHAINS_DB_PATH")
config :environment, stacks_dir: System.get_env("STACKS_DIR", "/opt/stacks")

config :environment,
  deployment_worker_image:
    System.get_env("DEPLOYMENT_WORKER_IMAGE", "makerdao/testchain-deployment-worker:dev")

config :event_stream, nats: %{host: System.fetch_env!("NATS_URL"), port: 4222}

config :testchain, host: System.get_env("HOST", "staxx.local")
config :testchain, internal_host: System.get_env("INTERNAL_EVM_HOST", "localhost")

config :testchain, nats: %{host: System.fetch_env!("NATS_URL"), port: 4222}

config :testchain, base_path: System.fetch_env!("CHAINS_DB_PATH")
config :testchain, snapshot_base_path: System.fetch_env!("SNAPSHOTS_DB_PATH")

config :testchain, front_url: System.fetch_env!("CHAINS_FRONT_URL")

# Place where all dets DBs will be
config :testchain, dets_db_path: System.fetch_env!("CHAINS_DB_PATH")

config :store, Staxx.Store.Repo, hostname: System.fetch_env!("POSTGRES_HOST")

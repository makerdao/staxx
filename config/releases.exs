import Config

# To set it to true, pass `DOCKER_DEV_MODE_ALLOWED=true`, all other variables will be interpritated as false
config :docker, dev_mode_allowed: System.fetch_env!("DOCKER_DEV_MODE_ALLOWED")

config :proxy, deployment_service_url: System.fetch_env!("DEPLOYMENT_SERVICE_URL")
config :proxy, deploy_chain_front_url: System.fetch_env!("CHAINS_FRONT_URL")
config :proxy, dets_db_path: System.fetch_env!("CHAINS_DB_PATH")
config :proxy, deployment_steps_fetch_timeout: 30_000

config :event_stream, nats: %{host: System.fetch_env!("NATS_URL"), port: 4222}

config :deployment_scope, stacks_dir: System.fetch_env!("STACKS_DIR")

config :ex_chain, base_path: System.fetch_env!("CHAINS_DB_PATH")
config :ex_chain, snapshot_base_path: System.fetch_env!("SNAPSHOTS_DB_PATH")
config :ex_chain, geth_executable: System.get_env("GETH_EXECUTABLE", "geth")
config :ex_chain, geth_password_file: System.get_env("EVM_ACCOUNT_PASSWORD", "/opt/built/priv/presets/geth/account_password")
config :ex_chain, ganache_executable: System.get_env("GANACHE_EXECUTABLE", "ganache-cli")
config :ex_chain, ganache_wrapper_file: System.get_env("GANACHE_WRAPPER", "/opt/built/priv/presets/ganache/wrapper.sh")
config :ex_chain, geth_vdb_executable: System.get_env("GETH_VDB_EXECUTABLE", "geth_vdb")

config :ex_chain, backend_proxy_node: System.get_env("STAXX_NODE", "staxx@staxx.local") |> String.to_atom()

config :ex_chain, front_url: System.fetch_env!("CHAINS_FRONT_URL")

# Place where all dets DBs will be
config :storage, dets_db_path: System.fetch_env!("CHAINS_DB_PATH")

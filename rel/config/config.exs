use Mix.Config

config :proxy, deployment_service_url: "http://testchain-deployment.local:5001/rpc"
config :proxy, deploy_chain_front_url: "host.docker.internal"
config :proxy, deployment_steps_fetch_timeout: 10_000

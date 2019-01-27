use Mix.Config

config :proxy, deployment_service_url: "http://testchain-deployment.local:5001/rpc"
config :proxy, deployment_steps_fetch_timeout: 10_000

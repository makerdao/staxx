defmodule Staxx.WebApiWeb.Router do
  use Staxx.WebApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Staxx.WebApiWeb do
    match :*, "/", IndexController, :index
    match :*, "/version", ChainController, :version
  end

  scope "/", Staxx.WebApiWeb do
    pipe_through :api
    post "/rpc", InternalController, :rpc
    get "/chains", ChainController, :list_chains
    post "/snapshots", ChainController, :upload_snapshot
    get "/snapshots/:chain", ChainController, :list_snapshots
    get "/snapshot/:id", ChainController, :download_snapshot
    delete "/snapshot/:id", ChainController, :remove_snapshot
  end

  scope "/deployment", Staxx.WebApiWeb do
    pipe_through :api
    get "/steps", DeploymentController, :steps
    # This is tmp route for testing only !
    post "/steps/reload", DeploymentController, :reload
    get "/commits", DeploymentController, :commit_list
  end

  scope "/chain", Staxx.WebApiWeb do
    pipe_through :api
    delete "/:id", ChainController, :remove_chain
    get "/:id", ChainController, :chain_details
    get "/stop/:id", ChainController, :stop
    post "/:id/take_snapshot", ChainController, :take_snapshot
    post "/:id/revert_snapshot/:snapshot", ChainController, :revert_snapshot
  end

  scope "/docker", Staxx.WebApiWeb do
    pipe_through :api
    post "/start", DockerController, :start
    get "/stop/:id", DockerController, :stop
  end

  scope "/environment", Staxx.WebApiWeb do
    pipe_through :api
    post "/start", EnvironmentController, :start
    get "/stop/:id", EnvironmentController, :stop
    get "/info/:id", EnvironmentController, :info
  end

  scope "/environment/extension", Staxx.WebApiWeb do
    pipe_through :api
    get "/list_config", ExtensionController, :list_config
    get "/reload_config", ExtensionController, :reload_config
    post "/start/:environment_id", ExtensionController, :start
    post "/stop/:environment_id", ExtensionController, :stop
    post "/notify", ExtensionController, :notify
    post "/notify/ready", ExtensionController, :notify_ready
    post "/notify/failed", ExtensionController, :notify_failed
  end

  scope "/user", Staxx.WebApiWeb do
    pipe_through :api
    get "/", UserController, :list
    get "/:id", UserController, :get
    post "/", UserController, :create
    post "/:id", UserController, :update
  end
end

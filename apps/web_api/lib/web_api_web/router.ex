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
  end

  scope "/docker", Staxx.WebApiWeb do
    pipe_through :api
    post "/start", DockerController, :start
    get "/stop/:id", DockerController, :stop
  end

  scope "/stack", Staxx.WebApiWeb do
    pipe_through :api
    get "/list", StackController, :list
    get "/reload", StackController, :reload_config
    post "/start", StackController, :start
    get "/stop/:id", StackController, :stop
    get "/info/:id", StackController, :info
    post "/manager/start/:id", StackController, :spawn_stack_manager
    post "/manager/stop/:id", StackController, :stop_stack_manager
    post "/notify", StackController, :notify
    post "/notify/ready", StackController, :stack_ready
    post "/notify/failed", StackController, :stack_failed
  end

  scope "/user", Staxx.WebApiWeb do
    pipe_through :api
    get "/", UserController, :list
    get "/:id", UserController, :get
    post "/", UserController, :create
    post "/:id", UserController, :update
  end
end

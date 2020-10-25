defmodule Staxx.WebApiWeb.Router do
  use Staxx.WebApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Staxx.WebApiWeb do
    match :*, "/", IndexController, :index
    match :*, "/version", IndexController, :version
    post "/rpc", InternalController, :rpc
  end

  scope "/deployments", Staxx.WebApiWeb do
    pipe_through :api
    get "/steps", DeploymentController, :steps
    # This is tmp route for testing only !
    post "/steps/reload", DeploymentController, :reload
    get "/commits", DeploymentController, :commit_list
  end

  scope "/containers", Staxx.WebApiWeb do
    pipe_through :api
    post "/start", DockerController, :start
    get "/:id/stop", DockerController, :stop
  end

  scope "/snapshots", Staxx.WebApiWeb do
    pipe_through :api
    post "/", SnapshotController, :upload_snapshot
    get "/:evm_type", SnapshotController, :list_snapshots
    get "/:id/download", SnapshotController, :download_snapshot
    delete "/:id", SnapshotController, :remove_snapshot
  end

  scope "/instances", Staxx.WebApiWeb do
    pipe_through :api
    get "/", InstancesController, :list
    post "/start", InstancesController, :start
    get "/:id", InstancesController, :info
    delete "/:id", InstancesController, :remove
    get "/:id/stop", InstancesController, :stop

    post "/:id/take_snapshot", SnapshotController, :take_snapshot
    post "/:id/revert_snapshot/:snapshot_id", SnapshotController, :revert_snapshot
  end

  scope "/stacks", Staxx.WebApiWeb do
    pipe_through :api
    get "/list_config", StackController, :list_config
    get "/reload_config", StackController, :reload_config

    # Debug & helper routes. Not for all use !
    post "/start/:instance_id", StackController, :start
    post "/stop/:instance_id", StackController, :stop
    post "/notify", StackController, :notify
    post "/notify/ready", StackController, :notify_ready
    post "/notify/failed", StackController, :notify_failed
  end

  scope "/user", Staxx.WebApiWeb do
    pipe_through :api
    get "/", UserController, :list
    get "/:id", UserController, :get
    post "/", UserController, :create
    post "/:id", UserController, :update
  end
end

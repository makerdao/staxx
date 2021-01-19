defmodule Staxx.WebApiWeb.Router do
  use Staxx.WebApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Staxx.WebApiWeb do
    match :*, "/", IndexController, :index
    match :*, "/version", IndexController, :version
  end

  # Backward compatability
  # TODO: Remove after updating all dependencies.
  # Currently required for deployment services.
  scope "/", Staxx.WebApiWeb.Api.V1 do
    pipe_through :api

    post "/rpc", RpcController, :handle
  end

  scope "/api", Staxx.WebApiWeb do
    pipe_through :api

    scope "/v1", Api.V1 do
      scope "/" do
        post "/rpc", RpcController, :handle
      end

      scope "/deployments" do
        get "/steps", DeploymentController, :steps
        # This is tmp route for testing only !
        post "/steps/reload", DeploymentController, :reload
        get "/commits", DeploymentController, :commit_list
      end

      scope "/containers" do
        post "/start", DockerController, :start
        get "/:id/stop", DockerController, :stop
      end

      scope "/snapshots" do
        post "/", SnapshotController, :upload_snapshot
        get "/:evm_type", SnapshotController, :list_snapshots
        get "/:id/download", SnapshotController, :download_snapshot
        delete "/:id", SnapshotController, :remove_snapshot
      end

      scope "/instances" do
        get "/", InstancesController, :list
        post "/start", InstancesController, :start
        get "/:id", InstancesController, :info
        delete "/:id", InstancesController, :remove
        get "/:id/stop", InstancesController, :stop

        post "/:id/take_snapshot", SnapshotController, :take_snapshot
        post "/:id/revert_snapshot/:snapshot_id", SnapshotController, :revert_snapshot
      end

      scope "/stacks" do
        get "/list_config", StackController, :list_config
        get "/reload_config", StackController, :reload_config

        # Debug & helper routes. Not for all use !
        post "/start/:instance_id", StackController, :start
        post "/stop/:instance_id", StackController, :stop
        post "/notify", StackController, :notify
        post "/notify/ready", StackController, :notify_ready
        post "/notify/failed", StackController, :notify_failed
      end

      scope "/user" do
        get "/", UserController, :list
        get "/:id", UserController, :get
        post "/", UserController, :create
        post "/:id", UserController, :update
      end
    end
  end
end

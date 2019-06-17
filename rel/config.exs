# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  # If you are running Phoenix, you should make sure that
  # server: true is set and the code reloader is disabled,
  # even in dev mode.
  # It is recommended that you build with MIX_ENV=prod and pass
  # the --env flag to Distillery explicitly if you want to use
  # dev mode.
  set dev_mode: true
  set include_erts: false
  # set cookie: :"5@X)NUmG78/qVM{Ij@4.x,D_Iv%H:HcT_Hk!?$cQydRo,Hc^@rUq~Ktjf?9cf<B%"
  set cookie: :"$[lJfA[r)l1s3J1*,El~/2Bpp`F$$eWUIYts<lp~&_!nV*:spSR%z:/Irisu87fr"
end

environment :prod do
  set include_erts: true
  set include_src: false
  # set cookie: :"m}2ynMI,/rbSQZ:Cv%V.~LTxDIDAWcj|H7nR9:P,6&BwxKEts(3[9@Ual5p7P%E,"
  set cookie: :"W_cC]7^rUeVZc|}$UL{@&1sQwT3}p507mFlh<E=/f!cxWI}4gpQx7Yu{ZUaD0cuK"
  set vm_args: "rel/vm.args"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :testchain_backendgateway do
  set version: "0.1.0"
  set applications: [
    :runtime_tools,
    event_bus: :permanent,
    docker: :permanent,
    proxy: :permanent,
    stacks: :permanent,
    web_api: :permanent
  ]

  set config_providers: [
    {Mix.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
  ]
  set overlays: [
    {:copy, "rel/config/config.exs", "etc/config.exs"}
  ]
end

defmodule Staxx.WebApiWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use WebApiWeb, :controller
      use WebApiWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: WebApiWeb

      import Plug.Conn
      import Staxx.WebApiWeb.Gettext
      alias Staxx.WebApiWeb.Router.Helpers, as: Routes

      # Fetch user email from request
      def get_user_email(conn) do
        case get_req_header(conn, "x-user-email") do
          [email] when is_binary(email) ->
            email

          _ ->
            nil
        end
      end
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/web_api_web/templates",
        namespace: Staxx.WebApiWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      import Staxx.WebApiWeb.ErrorHelpers
      import Staxx.WebApiWeb.Gettext
      alias Staxx.WebApiWeb.Router.Helpers, as: Routes
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import Staxx.WebApiWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

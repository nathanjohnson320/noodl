defmodule NoodlWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use NoodlWeb, :controller
      use NoodlWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: NoodlWeb

      import Plug.Conn
      import NoodlWeb.Gettext
      import Phoenix.LiveView.Controller
      alias NoodlWeb.Router.Helpers, as: Routes
      alias NoodlWeb.Live

      def redirect_back(conn) do
        Phoenix.Controller.redirect(conn, to: NavigationHistory.last_path(conn, 1) || "/")
      end
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/noodl_web/templates",
        namespace: NoodlWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import NoodlWeb.ErrorHelpers
      import NoodlWeb.Gettext
      import Phoenix.LiveView.Helpers
      import NoodlWeb.LiveHelpers
      alias NoodlWeb.Router.Helpers, as: Routes
      alias NoodlWeb.Live
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {NoodlWeb.LayoutView, "live.html"}

      alias NoodlWeb.Plug.Authentication

      unquote(view_helpers())
    end
  end

  def bare_view do
    quote do
      use Phoenix.LiveView,
        layout: {NoodlWeb.LayoutView, "bare.html"}

      alias NoodlWeb.Plug.Authentication

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers
      import NoodlWeb.LiveHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import NoodlWeb.ErrorHelpers
      import NoodlWeb.Gettext
      alias NoodlWeb.Router.Helpers, as: Routes
      alias NoodlWeb.Live
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import NoodlWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

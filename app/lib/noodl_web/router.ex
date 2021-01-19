defmodule NoodlWeb.Router do
  use NoodlWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {NoodlWeb.LayoutView, :root}
    plug NoodlWeb.Plug.UserAgent
    plug NoodlWeb.Plug.Authentication
    plug NavigationHistory.Tracker, excluded_paths: ["/login", "/sign-up"], history_size: 3
  end

  pipeline :browser_hook do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_secure_browser_headers
  end

  pipeline :logged_in do
    plug NoodlWeb.Plug.ValidateUser
  end

  pipeline :event_manager do
    plug NoodlWeb.Plug.ValidateEventManager
  end

  pipeline :capacity_check do
    plug NoodlWeb.Plug.ValidateSpectator
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :stripe do
    plug :accepts, ["json"]
    plug NoodlWeb.Plug.StripeValidator
  end

  scope "/", NoodlWeb do
    pipe_through :browser

    live "/", Live.Pages.Index

    # User routes
    live "/sign-up", Live.Accounts.SignUp, :sign_up
    post "/sign-up", AccountsController, :sign_up

    live "/login", Live.Accounts.Login, :login
    post "/login", AccountsController, :login

    get "/logout", AccountsController, :logout
    get "/unsubscribe", AccountsController, :unsubscribe

    get "/oauth/connect", AccountsController, :connect
    get "/:provider/oauth/callback", AccountsController, :oauth

    # Legal stuff
    live "/terms-and-conditions", Live.Pages.TermsAndConditions
    live "/privacy-policy", Live.Pages.PrivacyPolicy
  end

  scope "/guide", NoodlWeb do
    pipe_through :browser

    live "/", Live.Guide.Index
    live "/stream", Live.Guide.Stream
  end

  scope "/account", NoodlWeb do
    pipe_through :browser

    get "/confirmation", AccountsController, :confirmation

    live "/password-reset", Live.Accounts.PasswordReset
    live "/forgot-password", Live.Accounts.ForgotPassword
  end

  scope "/profile", NoodlWeb.Live.Accounts do
    pipe_through [:browser, :logged_in]

    live "/", Profile
    live "/security", Security
    live "/events", Events
    live "/notifications", Notifications
    live "/communications", Communication
  end

  scope "/ticket", NoodlWeb do
    pipe_through [:browser, :logged_in]

    live "/checkout", Live.Ticketing.Release.Checkout
    post "/checkout", ReleaseController, :checkout

    get "/checkout/completed", ReleaseController, :completed
  end

  scope "/events", NoodlWeb do
    pipe_through [:browser, :logged_in]

    live "/:id/proposals/new", Live.Events.Proposal.New

    live "/new", Live.Events.New, :new
    post "/new", EventsController, :payment
  end

  scope "/events", NoodlWeb do
    pipe_through [:browser, :capacity_check]

    live "/:event/sessions/:session",
         Live.Events.Session.Dashboard,
         :dashboard
  end

  scope "/events", NoodlWeb do
    pipe_through :browser

    live "/", Live.Events.Index, :index
    live "/:id", Live.Events.Show, :show
    live "/:id/recordings", Live.Events.Recordings
    live "/:id/members", Live.Events.Members

    get "/:id/calendar", EventsController, :calendar
    get "/:id/calendar/:session", EventsController, :calendar
  end

  scope "/events", NoodlWeb do
    pipe_through [:browser, :logged_in, :event_manager]

    live "/:id/manage", Live.Events.Manage
    live "/:id/manage/:view", Live.Events.Manage
    get "/:id/recording/:recording_id/download", EventsController, :download_recording
  end

  # Other scopes may use custom stacks.
  scope "/stripe", NoodlWeb do
    pipe_through :stripe

    post "/webhook", WebhookController, :stripe
  end

  scope "/", NoodlWeb do
    pipe_through :browser_hook
    post "/:provider/oauth/callback", AccountsController, :oauth
  end

  scope "/agora", NoodlWeb do
    pipe_through :api

    post "/webhook", WebhookController, :agora
    get "/webhook", WebhookController, :agora
  end

  if Mix.env() == :dev do
    scope "/livestream", NoodlWeb do
      post "/play", WebhookController, :livestream
      post "/publish", WebhookController, :livestream
      post "/done", WebhookController, :livestream
      post "/recording-done", WebhookController, :livestream
    end
  end

  scope "/" do
    # local email previews
    if Mix.env() == :dev || System.get_env("SMTP_PASSWORD") == nil do
      forward "/sent_emails", Bamboo.SentEmailViewerPlug
    end
  end
end

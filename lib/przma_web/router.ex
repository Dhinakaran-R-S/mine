# lib/przma_web/router.ex
defmodule PrzmaWeb.Router do
  use PrzmaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PrzmaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes (no authentication required)
  scope "/", PrzmaWeb do
    pipe_through :browser

    # Authentication routes
    live "/auth", AuthLive, :index
    live "/forgot_password", ForgotPasswordLive, :index
    live "/reset_password/:token", ResetPasswordLive, :show
    live "/otp_verify/:user_id", OTPVerifyLive, :show

    # Redirect root to auth
    get "/", PageController, :home
    # Or you can redirect directly to auth:
    # live "/", AuthLive, :index
  end

  # Protected routes - require valid session
  scope "/", PrzmaWeb do
    pipe_through :browser

    # User dashboard (for regular users and superadmins)
    live "/welcome", WelcomeLive, :index

    # Admin-only routes
    live "/admin/dashboard", AdminDashboardLive, :index

    # You can add more admin routes here like:
    # live "/admin/users", AdminUsersLive, :index
    # live "/admin/users/:id", AdminUserDetailLive, :show
    # live "/admin/settings", AdminSettingsLive, :index
  end

  # API routes (if needed)
  scope "/api", PrzmaWeb do
    pipe_through :api

    # Add API routes here if needed
    # For example, for mobile apps or external integrations
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:przma, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PrzmaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

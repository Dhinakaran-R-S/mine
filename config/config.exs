# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# config/config.exs

config :przma,
  ecto_repos: [Przma.Repo]

config :przma,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :przma, PrzmaWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PrzmaWeb.ErrorHTML, json: PrzmaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Przma.PubSub,
  live_view: [signing_salt: "M7iYafCI"]


#     config :przma, Przma.Mailer,
#   adapter: Swoosh.Adapters.Mailgun,
#   api_key: "2c34ae6553aa771a6fca1144c0079a6a-1ae02a08-9f9aaff2",
#   domain: "sandbox65ce9b12ed8a46c884a1064ffd7e4e6f.mailgun.org"

# config :swoosh, :api_client, Swoosh.ApiClient.Finch

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
# config :przma, Przma.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  przma: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  przma: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
# mail
#  config :przma, VideoApp.Mailer,
#   adapter: Swoosh.Adapters.Mailgun,
#   api_key: "258affb20f6f928822e171ebcd137c33-16bc1610-75fe5e60",
#   domain: "sandbox9f49599cc4134403aa6beaef83a7ce80.mailgun.org"

# config :swoosh, :api_client, Swoosh.ApiClient.Finch

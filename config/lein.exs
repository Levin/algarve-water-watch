# custom database setup

config :algground, Algground.Repo,
  username: "lein",
  password: "",
  hostname: "localhost",
  database: "algground_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
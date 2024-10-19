defmodule Algground.Repo do
  use Ecto.Repo,
    otp_app: :algground,
    adapter: Ecto.Adapters.Postgres
end

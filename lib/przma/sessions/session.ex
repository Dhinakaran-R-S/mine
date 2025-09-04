# lib/przma/sessions/session.ex
defmodule Przma.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:session_id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "auth"

  schema "sessions" do
    field :refresh_token, :string
    field :token_hash, :string
    field :status, :string, default: "active"
    # field :ip_address, EctoNetwork.INET
    field :user_agent, :string
    field :device_id, :string
    field :location_data, :map
    field :expires_at, :utc_datetime
    field :last_accessed_at, :utc_datetime

    # Associations
    belongs_to :user, Przma.Accounts.User,
      references: :user_id,
      foreign_key: :user_id,
      type: :binary_id

    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: false)
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [
      :user_id, :refresh_token, :token_hash, :status, :expires_at,
      :last_accessed_at, :created_at, :device_id, :user_agent,
      :ip_address, :location_data
    ])
    |> validate_required([:user_id, :refresh_token, :token_hash, :status])
    |> validate_inclusion(:status, ["active", "expired", "revoked"])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:refresh_token)
    |> put_defaults()
  end

  defp put_defaults(changeset) do
    now = DateTime.truncate(DateTime.utc_now(), :second)

    changeset
    |> put_change(:created_at, now)
    |> put_change(:last_accessed_at, now)
    |> put_change(:expires_at, DateTime.add(now, 24 * 60 * 60)) # 24 hours
    |> put_change(:device_id, "web_browser")
    |> put_change(:user_agent, get_field(changeset, :user_agent) || "unknown")
  end
end

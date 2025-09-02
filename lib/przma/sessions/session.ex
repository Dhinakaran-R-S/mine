defmodule Przma.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset
 # alias EctoNetwork.INET

  @primary_key {:session_id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "auth"
  schema "sessions" do
    field :user_id, :binary_id
    field :refresh_token, :string
    field :token_hash, :string
    field :status, :string
    field :ip_address, EctoNetwork.INET
    field :user_agent, :string
    field :device_id, :string
    field :location_data, :map
    field :expires_at, :utc_datetime
    field :last_accessed_at, :utc_datetime

    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: false)
  end

def changeset(session, attrs) do
  session
  |> cast(attrs, [
    :user_id,
    :refresh_token,
    :token_hash,
    :status,
    :expires_at,
    :last_accessed_at,
    :created_at,
    :device_id,
    :user_agent
  ])
  |> validate_required([:user_id, :refresh_token, :token_hash, :status, :created_at])
  |> check_constraint(:refresh_token, name: :valid_refresh_token)
  |> put_default_device_info()
end

defp put_default_device_info(changeset) do
  changeset
  |> put_change(:device_id, get_field(changeset, :device_id) || "unknown")
  |> put_change(:user_agent, get_field(changeset, :user_agent) || "unknown")
end
end

defmodule Przma.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Pbkdf2

  @primary_key {:user_id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "auth"
  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :deleted_at, :utc_datetime

    # # Other optional fields
    # field :salt, :string
    # field :auth_provider, :string
    # field :external_provider_id, :string
    # field :mfa_enabled, :boolean
    # field :mfa_type, :string
    # field :mfa_secret, :string
    # field :is_active, :boolean
    # field :is_verified, :boolean
    # field :failed_login_attempts, :integer
    # field :account_locked_until, :utc_datetime
    # field :last_login_at, :utc_datetime
    # field :password_changed_at, :utc_datetime
    # field :email_verified_at, :utc_datetime
    has_many :sessions, Przma.Sessions.Session, foreign_key: :user_id

    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: :updated_at)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :username, :password])
    |> validate_required([:first_name, :last_name, :password])
    |> put_username_if_nil()
    |> put_password_hash()
    |> validate_length(:first_name, max: 100)
    |> validate_length(:last_name, max: 100)
    |> validate_email()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Przma.Repo, message: "email already exists")
    |> unique_constraint(:email)
  end

  # Auto-generate username if nil
  defp put_username_if_nil(changeset) do
    if get_field(changeset, :username) == nil do
      first_name = get_field(changeset, :first_name) || "user"
      last_name = get_field(changeset, :last_name) || "unknown"
      username = String.downcase("#{first_name}_#{last_name}")
      put_change(changeset, :username, username)
    else
      changeset
    end
  end

  # Hash password using pbkdf2_elixir
  defp put_password_hash(changeset) do
    if password = get_change(changeset, :password) do
      put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(password))
    else
      changeset
    end
  end
end

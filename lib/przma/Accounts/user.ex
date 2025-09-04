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
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string
    field :deleted_at, :utc_datetime


    field :otp_code, :string
    field :otp_expires_at, :utc_datetime
    field :otp_used, :boolean, default: false

    field :reset_password_token, :string
    field :reset_password_sent_at, :naive_datetime

    # Add these essential fields from the second version
    field :is_active, :boolean, default: true
    field :is_verified, :boolean, default: false
    field :auth_provider, :string, default: "local"
    field :failed_login_attempts, :integer, default: 0
    field :last_login_at, :utc_datetime
    field :password_changed_at, :utc_datetime

    has_many :sessions, Przma.Sessions.Session, foreign_key: :user_id

    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: :updated_at)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :username, :password, :password_confirmation])
    |> validate_required([:first_name, :last_name, :email, :password, :password_confirmation])
    |> validate_length(:first_name, min: 1, max: 100)
    |> validate_length(:last_name, min: 1, max: 100)
    |> validate_length(:password, min: 8, max: 72)
    |> validate_password_confirmation()
    |> put_username_if_nil()
    |> put_password_hash()
    |> validate_email()
    |> put_default_values()
  end

    @doc """
  Changeset specifically for OTP updates
  """
  def otp_changeset(user, attrs) do
    user
    |> cast(attrs, [:otp_code, :otp_expires_at, :otp_used])
    |> validate_required([:otp_code, :otp_expires_at])
  end

  @doc """
  Changeset for marking OTP as used
  """
  def mark_otp_used_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:otp_used, :otp_code, :otp_expires_at])
    |> put_change(:otp_used, true)
    |> put_change(:otp_code, nil)
    |> put_change(:otp_expires_at, nil)
  end

  @doc """
  Changeset for verifying user
  """
  def verify_user_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:is_verified])
    |> put_change(:is_verified, true)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 160)
    |> update_change(:email, &String.downcase/1)
    |> unsafe_validate_unique(:email, Przma.Repo, message: "email already exists")
    |> unique_constraint(:email)
  end

  # Auto-generate username if nil - FIXED THE TYPO
  defp put_username_if_nil(changeset) do
    if get_field(changeset, :username) == nil do
      first_name = get_field(changeset, :first_name) || "user"
      last_name = get_field(changeset, :last_name) || "unknown"
      # Fixed: firstname -> first_name
      username = String.downcase("#{first_name}#{last_name}")
      put_change(changeset, :username, username)
    else
      changeset
    end
  end

  # Hash password using pbkdf2_elixir - SIMPLIFIED
  defp put_password_hash(changeset) do
    if password = get_change(changeset, :password) do
      changeset
      |> put_change(:password_hash, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
      |> delete_change(:password_confirmation)
    else
      changeset
    end
  end

  # Add default values
  defp put_default_values(changeset) do
    changeset
    |> put_change(:is_active, true)
    |> put_change(:is_verified, false)
    |> put_change(:auth_provider, "local")
    |> put_change(:failed_login_attempts, 0)
  end

  # Optional: Add password confirmation validation
  defp validate_password_confirmation(changeset) do
    validate_confirmation(changeset, :password, message: "does not match password")
  end

  @doc false
  def reset_password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> validate_password_strength()  # Use existing validation
    |> put_password_hash()
    |> clear_reset_token()  # Clear the reset token after successful reset
  end

  def reset_token_changeset(user, attrs) do
    user
    |> cast(attrs, [:reset_password_token, :reset_password_sent_at])
    |> validate_required([:reset_password_token, :reset_password_sent_at])
  end

  # Clear reset token and timestamp
  defp clear_reset_token(changeset) do
    changeset
    |> put_change(:reset_password_token, nil)
    |> put_change(:reset_password_sent_at, nil)
  end

  # Add password strength validation
  defp validate_password_strength(changeset) do
    password = get_change(changeset, :password)

    if password do
      case validate_password_requirements(password) do
        :ok -> changeset
        {:error, message} -> add_error(changeset, :password, message)
      end
    else
      changeset
    end
  end

  defp validate_password_requirements(password) do
    cond do
      String.length(password) < 8 ->
        {:error, "must be at least 8 characters long"}

      not String.match?(password, ~r/[A-Z]/) ->
        {:error, "must contain at least one uppercase letter"}

      not String.match?(password, ~r/[a-z]/) ->
        {:error, "must contain at least one lowercase letter"}

      not String.match?(password, ~r/[0-9]/) ->
        {:error, "must contain at least one number"}

      true ->
        :ok
    end
  end
end

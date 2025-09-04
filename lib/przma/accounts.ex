# lib/przma/accounts.ex
defmodule Przma.Accounts do
  @moduledoc """
  The Accounts context for managing users.
  """

  import Ecto.Query, warn: false
  alias Przma.Repo
  alias Przma.Accounts.User

  @doc """
  Returns the list of users (only active ones).
  """
  def list_users do
    Repo.all(from u in User, where: is_nil(u.deleted_at))
  end

  @doc """
  Gets a single user by user_id.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user by user_id, returns nil if not found.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by username.
  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user's information.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Soft deletes a user by setting deleted_at timestamp.
  """
  def delete_user(%User{} = user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    user
    |> Ecto.Changeset.change(deleted_at: now)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Search users by first_name, last_name, or email.
  """
  def search_users(search_term) do
    search_pattern = "%#{search_term}%"

    Repo.all(
      from u in User,
      where: ilike(u.first_name, ^search_pattern)
         or ilike(u.last_name, ^search_pattern)
         or ilike(u.email, ^search_pattern),
      where: is_nil(u.deleted_at)
    )
  end

  @doc """
  Get user's full name.
  """
  def get_full_name(%User{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end

  @doc """
  Checks if a user exists with the given email.
  """
  def user_exists?(email) when is_binary(email) do
    case get_user_by_email(email) do
      nil -> false
      %User{} -> true
    end
  end

  @doc """
  Get all active users count.
  """
  def get_active_users_count do
    Repo.aggregate(
      from(u in User, where: is_nil(u.deleted_at)),
      :count,
      :user_id
    )
  end

  @doc """
  Authenticates a user with email and password.
  """
  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    case get_user_by_email(email) do
      nil ->
        # Run password hash to prevent timing attacks
        Pbkdf2.no_user_verify()
        {:error, :invalid_credentials}

      %User{deleted_at: deleted_at} when not is_nil(deleted_at) ->
        {:error, :account_deactivated}

      %User{} = user ->
        if Pbkdf2.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Validates password strength.
  """
  def validate_password(password) when is_binary(password) do
    cond do
      String.length(password) < 8 ->
        {:error, "Password must be at least 8 characters long"}

      not String.match?(password, ~r/[A-Z]/) ->
        {:error, "Password must contain at least one uppercase letter"}

      not String.match?(password, ~r/[a-z]/) ->
        {:error, "Password must contain at least one lowercase letter"}

      not String.match?(password, ~r/[0-9]/) ->
        {:error, "Password must contain at least one number"}

      true ->
        :ok
    end
  end

  @doc """
  Updates user's last login timestamp.
  """
  def update_last_login(%User{} = user) do
    now = DateTime.truncate(DateTime.utc_now(), :second)
    user
    |> Ecto.Changeset.change(last_login_at: now)
    |> Repo.update()
  end

  # ------------------------
  # OTP Functions for User Table
  # ------------------------

  @doc """
  Updates user with OTP code and expiry.
  """
  def update_user_otp(%User{} = user, code, expires_at) do
    attrs = %{
      otp_code: code,
      otp_expires_at: expires_at,
      otp_used: false
    }

    user
    |> User.otp_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Generates and updates user with new OTP.
  """
  def generate_and_update_otp(%User{} = user) do
    code = :rand.uniform(899_999) + 100_000 |> Integer.to_string()
    now = DateTime.truncate(DateTime.utc_now(), :second)
    otp_expires_at = DateTime.add(now, 60) # 5 minutes

    update_user_otp(user, code, otp_expires_at)
  end

  @doc """
  Verifies OTP for a user.
  """
  def verify_otp(user_id, otp_code) do
    now = DateTime.utc_now()

    case Repo.get(User, user_id) do
      nil ->
        {:error, "User not found"}

      %User{otp_used: true} ->
        {:error, "OTP already used"}

      %User{otp_code: nil} ->
        {:error, "No OTP generated"}

      %User{otp_expires_at: nil} ->
        {:error, "Invalid OTP"}

      %User{otp_code: stored_code, otp_expires_at: otp_expires_at} = user ->
        if stored_code == otp_code do
          if DateTime.compare(otp_expires_at, now) == :gt do
            {:ok, user}
          else
            {:error, "OTP has expired"}
          end
        else
          {:error, "Invalid OTP code"}
        end
    end
  end

  @doc """
  Marks OTP as used for a user.
  """
  def mark_otp_used(%User{} = user) do
    user
    |> User.mark_otp_used_changeset()
    |> Repo.update()
  end

  @doc """
  Verifies user account (sets is_verified to true).
  """
  def verify_user(%User{} = user) do
    user
    |> User.verify_user_changeset()
    |> Repo.update()
  end

  def verify_user(user_id) when is_binary(user_id) do
    case get_user(user_id) do
      nil -> {:error, "User not found"}
      user -> verify_user(user)
    end
  end

  @doc """
  Sends OTP email to user.
  """
  def send_otp_email(%User{} = user, otp_code) do
    otp_url = "http://localhost:4000/otp_verify/#{user.user_id}"

    # Create email using Swoosh
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Przma", "no-reply@przma.com"})
      |> Swoosh.Email.to(user.email)
      |> Swoosh.Email.subject("Your OTP Verification Code")
      |> Swoosh.Email.html_body("""
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Welcome to Przma!</h2>
        <p>Hello #{user.first_name},</p>
        <p>Thank you for registering with Przma. To complete your account verification, please use the OTP code below:</p>

        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;">
          <h1 style="color: #4f46e5; font-size: 32px; margin: 0; letter-spacing: 4px;">#{otp_code}</h1>
        </div>

        <p>Alternatively, you can verify your account by clicking the link below:</p>
        <p><a href="#{otp_url}" style="color: #4f46e5;">Verify OTP</a></p>

        <p><strong>This OTP expires in 5 minutes.</strong></p>

        <p>If you didn't create an account with us, please ignore this email.</p>

        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        <p style="color: #666; font-size: 14px;">
          This is an automated message from Przma. Please do not reply to this email.
        </p>
      </div>
      """)

    # Send email - adjust this based on your mailer setup
    case Przma.Mailer.deliver(email) do
      {:ok, _response} ->
        IO.puts("OTP email sent successfully to #{user.email}")
        :ok
      {:error, reason} ->
        IO.puts("Failed to send OTP email: #{inspect(reason)}")
        {:error, reason}
    end
  rescue
    error ->
      IO.puts("Error sending OTP email: #{inspect(error)}")
      {:error, error}
  end

  @doc """
  Resends OTP to user.
  """
  def resend_otp(%User{} = user) do
    case generate_and_update_otp(user) do
      {:ok, updated_user} ->
        send_otp_email(updated_user, updated_user.otp_code)
        {:ok, updated_user}

      {:error, _changeset} = error ->
        error
    end
  end

  def resend_otp(user_id) when is_binary(user_id) do
    case get_user(user_id) do
      nil -> {:error, "User not found"}
      user -> resend_otp(user)
    end
  end

 # ------------------------
  # Password Reset Functions
  # ------------------------

  @doc """
  Generates a reset token for password reset.
  """
  def generate_reset_token(%User{} = user) do
    raw_token =
      :crypto.strong_rand_bytes(32)
      |> Base.url_encode64(padding: false)

    hashed_token =
      :crypto.hash(:sha256, raw_token)
      |> Base.encode16(case: :lower)

    sent_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    changeset =
      user
      |> User.reset_token_changeset(%{
        reset_password_token: hashed_token,
        reset_password_sent_at: sent_at
      })

    case Repo.update(changeset) do
      {:ok, updated_user} -> {:ok, raw_token, updated_user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Validates a reset token and returns the user if valid.
  """
  def validate_reset_token(token) when is_binary(token) do
    hashed_token =
      :crypto.hash(:sha256, token)
      |> Base.encode16(case: :lower)

    case Repo.get_by(User, reset_password_token: hashed_token) do
      nil ->
        {:error, :invalid_token}

      %User{deleted_at: deleted_at} when not is_nil(deleted_at) ->
        {:error, :account_deactivated}

      user ->
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        if user.reset_password_sent_at && NaiveDateTime.diff(now, user.reset_password_sent_at) <= 3600 do
          {:ok, user}
        else
          {:error, :expired_token}
        end
    end
  end

  @doc """
  Resets user password using a valid token.
  """
  def reset_password(token, new_password) when is_binary(token) and is_binary(new_password) do
    with {:ok, user} <- validate_reset_token(token) do
      changeset = User.reset_password_changeset(user, %{password: new_password})

      case Repo.update(changeset) do
        {:ok, updated_user} ->
          # Update password_changed_at timestamp
          now = DateTime.truncate(DateTime.utc_now(), :second)
          updated_user
          |> Ecto.Changeset.change(password_changed_at: now)
          |> Repo.update()

        {:error, changeset} = error ->
          error
      end
    end
  end

  @doc """
  Creates a changeset for forgot password email form.
  """
  def change_forgot_password_email(attrs \\ %{}) do
    data = %{"email" => ""}
    types = %{email: :string}

    {data, types}
    |> Ecto.Changeset.cast(attrs, Map.keys(types))
    |> Ecto.Changeset.validate_required([:email])
    |> Ecto.Changeset.validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
  end

  @doc """
  Sends password reset email to user.
  """
  def send_reset_password_email(%User{} = user, reset_token) do
    reset_url = "http://localhost:4000/reset_password/#{reset_token}"

    # Create email using Swoosh
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Przma", "no-reply@przma.com"})
      |> Swoosh.Email.to(user.email)
      |> Swoosh.Email.subject("Reset Your Password - Przma")
      |> Swoosh.Email.html_body("""
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Password Reset Request</h2>
        <p>Hello #{user.first_name},</p>
        <p>We received a request to reset your password for your Przma account.</p>

        <div style="background-color: #f8f9fa; padding: 20px; margin: 20px 0; border-radius: 8px; text-align: center;">
          <p style="margin-bottom: 15px;">Click the button below to reset your password:</p>
          <a href="#{reset_url}"
             style="display: inline-block; padding: 12px 24px; background-color: #4f46e5; color: white; text-decoration: none; border-radius: 6px; font-weight: bold;">
            Reset Password
          </a>
        </div>

        <p>Or copy and paste this link in your browser:</p>
        <p style="word-break: break-all; color: #4f46e5;"><a href="#{reset_url}">#{reset_url}</a></p>

        <p><strong>This link expires in 1 hour.</strong></p>

        <p>If you didn't request a password reset, please ignore this email or contact support if you have concerns.</p>

        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        <p style="color: #666; font-size: 14px;">
          This is an automated message from Przma. Please do not reply to this email.
        </p>
      </div>
      """)

    # Send email
    case Przma.Mailer.deliver(email) do
      {:ok, _response} ->
        IO.puts("Reset password email sent successfully to #{user.email}")
        :ok
      {:error, reason} ->
        IO.puts("Failed to send reset password email: #{inspect(reason)}")
        {:error, reason}
    end
  rescue
    error ->
      IO.puts("Error sending reset password email: #{inspect(error)}")
      {:error, error}
  end

  @doc """
  Initiates password reset process for a given email.
  """
  def initiate_password_reset(email) when is_binary(email) do
    case get_user_by_email(email) do
      nil ->
        # Don't reveal if email exists or not for security
        {:ok, :email_sent}

      %User{deleted_at: deleted_at} when not is_nil(deleted_at) ->
        {:error, :account_deactivated}

      %User{} = user ->
        case generate_reset_token(user) do
          {:ok, token, updated_user} ->
            case send_reset_password_email(updated_user, token) do
              :ok -> {:ok, :email_sent}
              {:error, _reason} -> {:error, :email_failed}
            end

          {:error, _changeset} ->
            {:error, :token_generation_failed}
        end
    end
  end

end

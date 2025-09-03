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
end

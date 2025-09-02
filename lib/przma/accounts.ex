defmodule Przma.Accounts do
  @moduledoc """
  The Accounts context for managing users.
  """

  import Ecto.Query, warn: false # allows you to write queries like from u in User
  alias Przma.Repo # lets you call Repo.insert, Repo.get etc. directly.
  alias Przma.Accounts.User #refers to the User schema.

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
end

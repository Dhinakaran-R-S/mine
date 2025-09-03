defmodule Przma.Sessions do
  @moduledoc """
  Simple Sessions context for managing user sessions.
  """

  import Ecto.Query, warn: false
  alias Przma.Repo
  alias Przma.Sessions.Session

  @doc """
  Creates a simple user session.
  """
  def create_user_session(user_id) do
    # Calculate expiry (30 days from now)
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(30, :day)
      |> DateTime.truncate(:second)

    attrs = %{
      user_id: user_id,
      refresh_token: generate_token(),
      token_hash: generate_token_hash(),
      status: "active",
      expires_at: expires_at,
      created_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets an active session by refresh token.
  """
  def get_active_session_by_token(token) do
    now = DateTime.truncate(DateTime.utc_now(), :second)

    Repo.one(
      from s in Session,
      where: s.refresh_token == ^token and s.status == "active" and s.expires_at > ^now
    )
  end

  @doc """
  Gets a session by session_id.
  """
  def get_session(session_id) do
    Repo.get(Session, session_id)
  end

  @doc """
  Validates if a session is still valid.
  """
  def valid_session?(%Session{} = session) do
    now = DateTime.truncate(DateTime.utc_now(), :second)
    session.status == "active" && DateTime.compare(session.expires_at, now) == :gt
  end

  @doc """
  Expires a session.
  """
  def expire_session(%Session{} = session) do
    session
    |> Ecto.Changeset.change(status: "expired")
    |> Repo.update()
  end

  @doc """
  Validates a session token and returns the session if valid.
  """
  def validate_session(token) do
    case get_active_session_by_token(token) do
      %Session{} = session ->
        if valid_session?(session) do
          {:ok, session}
        else
          expire_session(session)
          {:error, :expired}
        end

      nil ->
        {:error, :invalid}
    end
  end

  @doc """
  Cleans up expired sessions (for periodic cleanup).
  """
  def cleanup_expired_sessions do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(s in Session,
      where: s.expires_at < ^now or s.status != "active"
    )
    |> Repo.delete_all()
  end

  @doc """
  Generates a secure random token.
  """
  def generate_token(length \\ 32) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Generates a token hash.
  """
  def generate_token_hash(token \\ nil) do
    token = token || generate_token()
    :crypto.hash(:sha256, token)
    |> Base.encode16(case: :lower)
  end
end

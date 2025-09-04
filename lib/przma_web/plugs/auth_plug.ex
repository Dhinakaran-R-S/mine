defmodule PrzmaWeb.Plugs.AuthPlug do
  @moduledoc """
  Authentication and authorization plug with RBAC support.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias Przma.Accounts
  alias Przma.Sessions

  def init(opts), do: opts

  def call(conn, opts) do
    required_role = Keyword.get(opts, :role)

    with {:ok, token} <- get_token_from_params_or_session(conn),
         {:ok, session} <- get_valid_session(token),
         {:ok, user} <- get_user(session.user_id),
         :ok <- check_role_authorization(user, required_role) do

      conn
      |> assign(:current_user, user)
      |> assign(:current_session, session)
    else
      {:error, :no_token} ->
        redirect_to_auth(conn, "Authentication required")

      {:error, :invalid_session} ->
        redirect_to_auth(conn, "Invalid or expired session")

      {:error, :user_not_found} ->
        redirect_to_auth(conn, "User not found")

      {:error, :insufficient_privileges} ->
        conn
        |> put_flash(:error, "Access denied. Insufficient privileges.")
        |> redirect(to: "/welcome")
        |> halt()

      _ ->
        redirect_to_auth(conn, "Authentication failed")
    end
  end

  defp get_token_from_params_or_session(conn) do
    case conn.params["token"] || get_session(conn, :auth_token) do
      nil -> {:error, :no_token}
      token -> {:ok, token}
    end
  end

  defp get_valid_session(token) do
    case Sessions.get_active_session_by_token(token) do
      %Sessions.Session{} = session ->
        if Sessions.valid_session?(session) do
          {:ok, session}
        else
          {:error, :invalid_session}
        end

      nil ->
        {:error, :invalid_session}
    end
  end

  defp get_user(user_id) do
    case Accounts.get_user(user_id) do
      %Przma.Accounts.User{} = user -> {:ok, user}
      nil -> {:error, :user_not_found}
    end
  end

  defp check_role_authorization(_user, nil), do: :ok

  defp check_role_authorization(%Przma.Accounts.User{role: user_role}, required_role) do
    case {user_role, required_role} do
      {"superadmin", _} -> :ok  # Superadmins can access everything
      {role, role} -> :ok       # User has exact required role
      _ -> {:error, :insufficient_privileges}
    end
  end

  defp redirect_to_auth(conn, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: "/auth")
    |> halt()
  end
end

# lib/przma_web/plugs/auth_required.ex
defmodule PrzmaWeb.Plugs.AuthRequired do
  import Plug.Conn
  import Phoenix.Controller
  alias Przma.{Accounts, Sessions}

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, user_id} <- get_user_id_from_session(conn),
         {:ok, token} <- get_token_from_session(conn),
         {:ok, session} <- get_valid_session(token),
         {:ok, user} <- get_user(user_id) do

      conn
      |> assign(:current_user, user)
      |> assign(:current_session, session)
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "You must be logged in to access this page")
        |> redirect(to: "/auth")
        |> halt()
    end
  end

  defp get_user_id_from_session(conn) do
    case get_session(conn, :user_id) do
      nil -> {:error, :no_user_id}
      user_id -> {:ok, user_id}
    end
  end

  defp get_token_from_session(conn) do
    case get_session(conn, :auth_token) do
      nil -> {:error, :no_token}
      token -> {:ok, token}
    end
  end

  defp get_valid_session(token) do
    case Sessions.get_active_session_by_token(token) do
      nil -> {:error, :invalid_session}
      session ->
        if Sessions.valid_session?(session) do
          {:ok, session}
        else
          {:error, :expired_session}
        end
    end
  end

  defp get_user(user_id) do
    case Accounts.get_user(user_id) do
      nil -> {:error, :user_not_found}
      user ->
        if user.deleted_at do
          {:error, :user_deleted}
        else
          {:ok, user}
        end
    end
  end
end

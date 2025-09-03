defmodule PrzmaWeb.WelcomeLive do
  use PrzmaWeb, :live_view
  alias Przma.Accounts
  alias Przma.Sessions

  @impl true
  def mount(%{"token" => token, "user_id" => user_id}, _session, socket) do
    case Sessions.get_active_session_by_token(token) do
      %Sessions.Session{user_id: ^user_id} = session ->
        if Sessions.valid_session?(session) do
          case Accounts.get_user(user_id) do
            %Przma.Accounts.User{} = user ->
              {:ok,
               socket
               |> assign(:user, user)
               |> assign(:session, session)
               |> assign(:token, token)}

            nil ->
              {:ok, redirect_to_auth(socket, "User not found")}
          end
        else
          {:ok, redirect_to_auth(socket, "Session expired. Please log in again.")}
        end

      _ ->
        {:ok, redirect_to_auth(socket, "Invalid session. Please log in again.")}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, redirect_to_auth(socket, "Please log in to continue")}
  end

  defp redirect_to_auth(socket, msg) do
    socket
    |> put_flash(:error, msg)
    |> push_navigate(to: ~p"/auth")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="bg-white shadow rounded-lg p-8 text-center">
        <h1 class="text-2xl font-bold text-gray-900 mb-4">
          Welcome, <%= @user.first_name %> <%= @user.last_name %>!
        </h1>
        <button
          phx-click="logout"
          class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium"
        >
          Logout
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("logout", _params, socket) do
    Sessions.expire_session(socket.assigns.session)

    {:noreply,
     socket
     |> put_flash(:info, "Successfully logged out")
     |> push_navigate(to: ~p"/auth")}
  end
end

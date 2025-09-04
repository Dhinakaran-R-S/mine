defmodule PrzmaWeb.AdminDashboardLive do
  use PrzmaWeb, :live_view
  alias Przma.Accounts
  alias Przma.Sessions

  @impl true
  def mount(%{"token" => token, "user_id" => user_id}, _session, socket) do
    case Sessions.get_active_session_by_token(token) do
      %Sessions.Session{user_id: ^user_id} = session ->
        if Sessions.valid_session?(session) do
          case Accounts.get_user(user_id) do
            %Przma.Accounts.User{role: "superadmin"} = user ->
              {:ok,
               socket
               |> assign(:user, user)
               |> assign(:session, session)
               |> assign(:token, token)
               |> assign(:users, list_all_users())
               |> assign(:stats, get_admin_stats())}

            %Przma.Accounts.User{} ->
              {:ok, redirect_to_auth(socket, "Access denied. Admin privileges required.")}

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

  defp list_all_users do
    Accounts.list_users()
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
  end

  defp get_admin_stats do
    %{
      total_users: Accounts.get_active_users_count(),
      regular_users: Accounts.get_active_users_count_by_role("user"),
      superadmins: Accounts.get_active_users_count_by_role("superadmin"),
      verified_users: Accounts.list_users() |> Enum.count(& &1.is_verified),
      unverified_users: Accounts.list_users() |> Enum.count(&(!&1.is_verified))
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Navigation Header -->
      <nav class="bg-white shadow-sm border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <h1 class="text-xl font-bold text-gray-900">Przma Admin</h1>
              </div>
              <div class="ml-6">
                <div class="flex space-x-4">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                    Super Administrator
                  </span>
                </div>
              </div>
            </div>

            <div class="flex items-center space-x-4">
              <div class="flex items-center text-sm text-gray-700">
                <span class="font-medium"><%= @user.first_name %> <%= @user.last_name %></span>
              </div>

              <button
                phx-click="goto_user_dashboard"
                class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1.5 rounded-md text-sm font-medium transition-colors"
              >
                User View
              </button>

              <button
                phx-click="logout"
                class="bg-red-600 hover:bg-red-700 text-white px-3 py-1.5 rounded-md text-sm font-medium transition-colors"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      </nav>

      <!-- Main Content -->
      <div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="px-4 py-6 sm:px-0">

          

          <!-- Users Management Table -->
          <div class="bg-white shadow overflow-hidden sm:rounded-md">
            <div class="px-4 py-5 sm:px-6 border-b border-gray-200">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                User Management
              </h3>
              <p class="mt-1 max-w-2xl text-sm text-gray-500">
                Manage all users in the system. Click on actions to perform user operations.
              </p>
            </div>

            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      User
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Role
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Created
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Last Login
                    </th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr :for={user <- @users} class="hover:bg-gray-50">
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class={[
                          "h-10 w-10 rounded-full flex items-center justify-center text-white font-bold",
                          case user.role do
                            "superadmin" -> "bg-purple-500"
                            "user" -> "bg-blue-500"
                            _ -> "bg-gray-500"
                          end
                        ]}>
                          <%= String.first(user.first_name) %><%= String.first(user.last_name) %>
                        </div>
                        <div class="ml-4">
                          <div class="text-sm font-medium text-gray-900">
                            <%= user.first_name %> <%= user.last_name %>
                          </div>
                          <div class="text-sm text-gray-500">
                            <%= user.email %>
                          </div>
                        </div>
                      </div>
                    </td>

                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class={[
                        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                        case user.role do
                          "superadmin" -> "bg-purple-100 text-purple-800"
                          "user" -> "bg-blue-100 text-blue-800"
                          _ -> "bg-gray-100 text-gray-800"
                        end
                      ]}>
                        <%= Przma.Accounts.User.role_display(user) %>
                      </span>
                    </td>

                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex flex-col space-y-1">
                        <span class={[
                          "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                          if(user.is_active, do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800")
                        ]}>
                          <%= if user.is_active, do: "Active", else: "Inactive" %>
                        </span>
                        <span class={[
                          "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                          if(user.is_verified, do: "bg-emerald-100 text-emerald-800", else: "bg-yellow-100 text-yellow-800")
                        ]}>
                          <%= if user.is_verified, do: "Verified", else: "Unverified" %>
                        </span>
                      </div>
                    </td>

                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <%= Calendar.strftime(user.created_at, "%m/%d/%Y") %>
                    </td>

                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <%= if user.last_login_at do %>
                        <%= Calendar.strftime(user.last_login_at, "%m/%d/%Y") %>
                      <% else %>
                        <span class="text-gray-400">Never</span>
                      <% end %>
                    </td>

                    <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div class="flex justify-end space-x-2">
                        <button
                          phx-click="view_user"
                          phx-value-user-id={user.user_id}
                          class="text-indigo-600 hover:text-indigo-900 text-xs bg-indigo-50 hover:bg-indigo-100 px-2 py-1 rounded"
                        >
                          View
                        </button>
                        <%= if user.role != "superadmin" do %>
                          <%= if user.is_active do %>
                            <button
                              phx-click="deactivate_user"
                              phx-value-user-id={user.user_id}
                              class="text-red-600 hover:text-red-900 text-xs bg-red-50 hover:bg-red-100 px-2 py-1 rounded"
                              data-confirm="Are you sure you want to deactivate this user?"
                            >
                              Deactivate
                            </button>
                          <% else %>
                            <button
                              phx-click="activate_user"
                              phx-value-user-id={user.user_id}
                              class="text-green-600 hover:text-green-900 text-xs bg-green-50 hover:bg-green-100 px-2 py-1 rounded"
                            >
                              Activate
                            </button>
                          <% end %>
                        <% end %>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
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

  @impl true
  def handle_event("goto_user_dashboard", _params, socket) do
    user = socket.assigns.user
    token = socket.assigns.token

    {:noreply,
     socket
     |> push_navigate(to: ~p"/welcome?token=#{token}&user_id=#{user.user_id}")}
  end

  @impl true
  def handle_event("view_user", %{"user-id" => user_id}, socket) do
    case Accounts.get_user(user_id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "User not found")}

      user ->
        {:noreply,
         socket
         |> put_flash(:info, "Viewing user: #{user.first_name} #{user.last_name} (#{user.email})")}
    end
  end

  @impl true
  def handle_event("deactivate_user", %{"user-id" => user_id}, socket) do
    case Accounts.get_user(user_id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "User not found")}

      %Przma.Accounts.User{role: "superadmin"} ->
        {:noreply,
         socket
         |> put_flash(:error, "Cannot deactivate superadmin users")}

      user ->
        case Accounts.delete_user(user) do
          {:ok, _updated_user} ->
            {:noreply,
             socket
             |> put_flash(:info, "User deactivated successfully")
             |> assign(:users, list_all_users())
             |> assign(:stats, get_admin_stats())}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to deactivate user")}
        end
    end
  end

  @impl true
  def handle_event("activate_user", %{"user-id" => user_id}, socket) do
    case Accounts.get_user(user_id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "User not found")}

      user ->
        # Reactivate user by clearing deleted_at
        changeset = Ecto.Changeset.change(user, deleted_at: nil, is_active: true)

        case Przma.Repo.update(changeset) do
          {:ok, _updated_user} ->
            {:noreply,
             socket
             |> put_flash(:info, "User activated successfully")
             |> assign(:users, list_all_users())
             |> assign(:stats, get_admin_stats())}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to activate user")}
        end
    end
  end
end

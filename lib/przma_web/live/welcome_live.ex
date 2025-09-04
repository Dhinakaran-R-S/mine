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
               |> assign(:token, token)
               |> assign(:stats, get_user_stats(user))}

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

  defp get_user_stats(%Przma.Accounts.User{role: "superadmin"}) do
    %{
      total_users: Accounts.get_active_users_count(),
      regular_users: Accounts.get_active_users_count_by_role("user"),
      superadmins: Accounts.get_active_users_count_by_role("superadmin")
    }
  end

  defp get_user_stats(%Przma.Accounts.User{role: "user"}) do
    %{
      profile_complete: true, # You can add logic to check profile completion
      last_login: "Today"
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
                <h1 class="text-xl font-bold text-gray-900">Przma</h1>
              </div>
            </div>

            <div class="flex items-center space-x-4">
              <!-- Role Badge -->
              <span class={[
                "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                case @user.role do
                  "superadmin" -> "bg-purple-100 text-purple-800"
                  "user" -> "bg-blue-100 text-blue-800"
                  _ -> "bg-gray-100 text-gray-800"
                end
              ]}>
                <%= Przma.Accounts.User.role_display(@user) %>
              </span>

              <!-- User Info -->
              <div class="flex items-center text-sm text-gray-700">
                <span class="font-medium"><%= @user.first_name %> <%= @user.last_name %></span>
              </div>

              <!-- Logout Button -->
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

          <!-- Welcome Section -->
          <div class="bg-white overflow-hidden shadow rounded-lg mb-6">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <div class={[
                    "h-12 w-12 rounded-full flex items-center justify-center text-white font-bold text-lg",
                    case @user.role do
                      "superadmin" -> "bg-purple-500"
                      "user" -> "bg-blue-500"
                      _ -> "bg-gray-500"
                    end
                  ]}>
                    <%= String.first(@user.first_name) %><%= String.first(@user.last_name) %>
                  </div>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">
                      Welcome back
                    </dt>
                    <dd class="text-lg font-medium text-gray-900">
                      <%= @user.first_name %> <%= @user.last_name %>
                    </dd>
                    <dd class="text-sm text-gray-500">
                      Logged in as <%= Przma.Accounts.User.role_display(@user) %>
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <!-- Role-based Content -->
          <%= if @user.role == "superadmin" do %>
            <!-- Superadmin Dashboard -->
            <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 mb-6">
              <!-- Total Users Card -->
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class="h-8 w-8 bg-blue-500 rounded-full flex items-center justify-center">
                        <span class="text-white text-sm font-bold">U</span>
                      </div>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-medium text-gray-500 truncate">Total Users</dt>
                        <dd class="text-lg font-medium text-gray-900"><%= @stats.total_users %></dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Regular Users Card -->
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class="h-8 w-8 bg-green-500 rounded-full flex items-center justify-center">
                        <span class="text-white text-sm font-bold">R</span>
                      </div>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-medium text-gray-500 truncate">Regular Users</dt>
                        <dd class="text-lg font-medium text-gray-900"><%= @stats.regular_users %></dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Superadmins Card -->
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class="h-8 w-8 bg-purple-500 rounded-full flex items-center justify-center">
                        <span class="text-white text-sm font-bold">A</span>
                      </div>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-medium text-gray-500 truncate">Super Admins</dt>
                        <dd class="text-lg font-medium text-gray-900"><%= @stats.superadmins %></dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>
            </div>

          <% else %>
            <!-- Regular User Dashboard -->
            <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 mb-6">
              <!-- Profile Status Card -->
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class="h-8 w-8 bg-green-500 rounded-full flex items-center justify-center">
                        <span class="text-white text-sm">✓</span>
                      </div>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-medium text-gray-500 truncate">Profile Status</dt>
                        <dd class="text-lg font-medium text-gray-900">Completed</dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Account Status Card -->
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class={[
                        "h-8 w-8 rounded-full flex items-center justify-center text-white text-sm",
                        if(@user.is_verified, do: "bg-green-500", else: "bg-yellow-500")
                      ]}>
                        <%= if @user.is_verified, do: "✓", else: "⚠" %>
                      </div>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-medium text-gray-500 truncate">Account Status</dt>
                        <dd class="text-lg font-medium text-gray-900">
                          <%= if @user.is_verified, do: "Verified", else: "Pending Verification" %>
                        </dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- User Actions -->
            <%!-- <div class="bg-white shadow rounded-lg">
              <div class="px-4 py-5 sm:p-6">
                <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                  Available Actions
                </h3>
                <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <button
                    phx-click="edit_profile"
                    class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Edit Profile
                  </button>

                  <button
                    phx-click="change_password"
                    class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Change Password
                  </button>
                </div>
              </div>
            </div> --%>
          <% end %>

          <!-- Account Information -->
          <div class="mt-6 bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                Account Information
              </h3>
              <dl class="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
                <div>
                  <dt class="text-sm font-medium text-gray-500">Full name</dt>
                  <dd class="mt-1 text-sm text-gray-900"><%= @user.first_name %> <%= @user.last_name %></dd>
                </div>

                <div>
                  <dt class="text-sm font-medium text-gray-500">Email address</dt>
                  <dd class="mt-1 text-sm text-gray-900"><%= @user.email %></dd>
                </div>

                <div>
                  <dt class="text-sm font-medium text-gray-500">Username</dt>
                  <dd class="mt-1 text-sm text-gray-900"><%= @user.username %></dd>
                </div>

                <div>
                  <dt class="text-sm font-medium text-gray-500">Role</dt>
                  <dd class="mt-1">
                    <span class={[
                      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                      case @user.role do
                        "superadmin" -> "bg-purple-100 text-purple-800"
                        "user" -> "bg-blue-100 text-blue-800"
                        _ -> "bg-gray-100 text-gray-800"
                      end
                    ]}>
                      <%= Przma.Accounts.User.role_display(@user) %>
                    </span>
                  </dd>
                </div>

                <div>
                  <dt class="text-sm font-medium text-gray-500">Account status</dt>
                  <dd class="mt-1">
                    <span class={[
                      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                      if(@user.is_active, do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800")
                    ]}>
                      <%= if @user.is_active, do: "Active", else: "Inactive" %>
                    </span>
                  </dd>
                </div>

                <div>
                  <dt class="text-sm font-medium text-gray-500">Email verified</dt>
                  <dd class="mt-1">
                    <span class={[
                      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                      if(@user.is_verified, do: "bg-green-100 text-green-800", else: "bg-yellow-100 text-yellow-800")
                    ]}>
                      <%= if @user.is_verified, do: "Verified", else: "Pending" %>
                    </span>
                  </dd>
                </div>

                <%= if @user.last_login_at do %>
                  <div>
                    <dt class="text-sm font-medium text-gray-500">Last login</dt>
                    <dd class="mt-1 text-sm text-gray-900">
                      <%= Calendar.strftime(@user.last_login_at, "%B %d, %Y at %I:%M %p") %>
                    </dd>
                  </div>
                <% end %>

                <div>
                  <dt class="text-sm font-medium text-gray-500">Member since</dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    <%= Calendar.strftime(@user.created_at, "%B %d, %Y") %>
                  </dd>
                </div>
              </dl>
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

  # Superadmin-only actions
  @impl true
  def handle_event("manage_users", _params, socket) do
    user = socket.assigns.user

    if Accounts.can_manage_users?(user) do
      {:noreply,
       socket
       |> put_flash(:info, "Redirecting to user management...")
       |> push_navigate(to: ~p"/admin/users?token=#{socket.assigns.token}&user_id=#{user.user_id}")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Access denied. Insufficient privileges.")}
    end
  end

  @impl true
  def handle_event("view_system_logs", _params, socket) do
    user = socket.assigns.user

    if Accounts.can_view_system_settings?(user) do
      {:noreply,
       socket
       |> put_flash(:info, "System logs feature coming soon...")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Access denied. Insufficient privileges.")}
    end
  end

  @impl true
  def handle_event("system_settings", _params, socket) do
    user = socket.assigns.user

    if Accounts.can_view_system_settings?(user) do
      {:noreply,
       socket
       |> put_flash(:info, "System settings feature coming soon...")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Access denied. Insufficient privileges.")}
    end
  end

  # Regular user actions
  @impl true
  def handle_event("edit_profile", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Profile editing feature coming soon...")}
  end

  @impl true
  def handle_event("change_password", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Password change feature coming soon...")}
  end
end

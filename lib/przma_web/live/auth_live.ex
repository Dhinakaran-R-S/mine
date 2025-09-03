defmodule PrzmaWeb.AuthLive do
  use PrzmaWeb, :live_view
  alias Przma.Accounts
  alias Przma.Sessions

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_tab, "login")
      |> assign(:login_form, to_form(%{"email" => "", "password" => ""}))
      |> assign(:register_form, to_form(%{
        "first_name" => "",
        "last_name" => "",
        "email" => "",
        "password" => "",
        "password_confirmation" => ""
      }))
      |> assign(:errors, [])
      |> assign(:loading, false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Welcome to Przma
          </h2>
        </div>

        <!-- Tab Navigation -->
        <div class="flex border-b border-gray-200">
          <button
            phx-click="switch_tab"
            phx-value-tab="login"
            class={[
              "flex-1 py-2 px-1 text-center border-b-2 font-medium text-sm",
              if(@current_tab == "login", do: "border-indigo-500 text-indigo-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")
            ]}
          >
            Login
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="register"
            class={[
              "flex-1 py-2 px-1 text-center border-b-2 font-medium text-sm",
              if(@current_tab == "register", do: "border-indigo-500 text-indigo-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")
            ]}
          >
            Register
          </button>
        </div>

        <!-- Error Messages -->
        <div :if={@errors != []} class="bg-red-50 border border-red-200 rounded-md p-4">
          <div class="flex">
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">
                Please correct the following errors:
              </h3>
              <div class="mt-2 text-sm text-red-700">
                <ul class="list-disc pl-5 space-y-1">
                  <li :for={error <- @errors}><%= error %></li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <!-- Login Form -->
        <div :if={@current_tab == "login"} class="mt-8 space-y-6">
          <.form for={@login_form} phx-submit="login_submit" class="space-y-6">
            <div>
              <label for="email" class="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <div class="mt-1">
                <.input
                  field={@login_form[:email]}
                  type="email"
                  required
                  class="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  placeholder="Email address"
                />
              </div>
            </div>

            <div>
              <label for="password" class="block text-sm font-medium text-gray-700">
                Password
              </label>
              <div class="mt-1">
                <.input
                  field={@login_form[:password]}
                  type="password"
                  required
                  class="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  placeholder="Password"
                />
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={@loading}
                class={[
                  "group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
                  if(@loading,
                    do: "bg-indigo-400 cursor-not-allowed",
                    else: "bg-indigo-600 hover:bg-indigo-700")
                ]}
              >
                <%= if @loading, do: "Signing in...", else: "Sign in" %>
              </button>
            </div>
          </.form>
        </div>

        <!-- Register Form -->
        <div :if={@current_tab == "register"} class="mt-8 space-y-6">
          <.form for={@register_form} phx-submit="register_submit" class="space-y-6">
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label for="first_name" class="block text-sm font-medium text-gray-700">
                  First name
                </label>
                <div class="mt-1">
                  <.input
                    field={@register_form[:first_name]}
                    type="text"
                    required
                    class="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    placeholder="First name"
                  />
                </div>
              </div>

              <div>
                <label for="last_name" class="block text-sm font-medium text-gray-700">
                  Last name
                </label>
                <div class="mt-1">
                  <.input
                    field={@register_form[:last_name]}
                    type="text"
                    required
                    class="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    placeholder="Last name"
                  />
                </div>
              </div>
            </div>

            <div>
              <label for="email" class="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <div class="mt-1">
                <.input
                  field={@register_form[:email]}
                  type="email"
                  required
                  class="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  placeholder="Email address"
                />
              </div>
            </div>

            <div>
              <label for="password" class="block text-sm font-medium text-gray-700">
                Password
              </label>
              <div class="mt-1">
                <.input
                  field={@register_form[:password]}
                  type="password"
                  required
                  class="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  placeholder="Password"
                />
              </div>
              <p class="mt-1 text-xs text-gray-500">
                Must be at least 8 characters with uppercase, lowercase, and number
              </p>
            </div>

            <div>
              <label for="password_confirmation" class="block text-sm font-medium text-gray-700">
                Confirm Password
              </label>
              <div class="mt-1">
                <.input
                  field={@register_form[:password_confirmation]}
                  type="password"
                  required
                  class="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  placeholder="Confirm password"
                />
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={@loading}
                class={[
                  "group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
                  if(@loading,
                    do: "bg-indigo-400 cursor-not-allowed",
                    else: "bg-indigo-600 hover:bg-indigo-700")
                ]}
              >
                <%= if @loading, do: "Creating account...", else: "Create account" %>
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket =
      socket
      |> assign(:current_tab, tab)
      |> assign(:errors, [])
      |> assign(:loading, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("login_submit", %{"email" => email, "password" => password}, socket) do
    socket = assign(socket, :loading, true)

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # Update last login
        Accounts.update_last_login(user)

        # Create simple session
        case Sessions.create_user_session(user.user_id) do
          {:ok, session} ->
            # Redirect to welcome with token in URL
            {:noreply,
             socket
             |> put_flash(:info, "Login successful!")
             |> assign(:loading, false)
             |> push_navigate(to: ~p"/welcome?token=#{session.refresh_token}&user_id=#{user.user_id}")}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> assign(:errors, ["Failed to create session. Please try again."])
             |> assign(:loading, false)}
        end

      {:error, :invalid_credentials} ->
        {:noreply,
         socket
         |> assign(:errors, ["Invalid email or password"])
         |> assign(:loading, false)}

      {:error, :account_deactivated} ->
        {:noreply,
         socket
         |> assign(:errors, ["Account has been deactivated"])
         |> assign(:loading, false)}
    end
  end

  @impl true
  def handle_event("register_submit", params, socket) do
    socket = assign(socket, :loading, true)

    case Accounts.create_user(params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Registration successful! Please login.")
         |> assign(:current_tab, "login")
         |> assign(:errors, [])
         |> assign(:loading, false)}

      {:error, changeset} ->
        errors = extract_changeset_errors(changeset)
        {:noreply,
         socket
         |> assign(:errors, errors)
         |> assign(:loading, false)}
    end
  end

  # Private helper functions
  defp extract_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      "#{Phoenix.Naming.humanize(field)} #{List.first(errors)}"
    end)
  end
end

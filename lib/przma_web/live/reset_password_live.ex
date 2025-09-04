# lib/przma_web/live/reset_password_live.ex

defmodule PrzmaWeb.ResetPasswordLive do
  use PrzmaWeb, :live_view
  alias Przma.Accounts
  alias Przma.Accounts.User

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Accounts.validate_reset_token(token) do
      {:ok, user} ->
        socket =
          socket
          |> assign(:token, token)
          |> assign(:user, user)
          |> assign(:form, to_form(%{"password" => "", "password_confirmation" => ""}))
          |> assign(:error, nil)
          |> assign(:success, nil)
          |> assign(:loading, false)

        {:ok, socket}

      {:error, :invalid_token} ->
        socket =
          socket
          |> assign(:token, nil)
          |> assign(:user, nil)
          |> assign(:form, nil)
          |> assign(:error, "Invalid reset link. Please request a new password reset.")
          |> assign(:success, nil)
          |> assign(:loading, false)

        {:ok, socket}

      {:error, :expired_token} ->
        socket =
          socket
          |> assign(:token, nil)
          |> assign(:user, nil)
          |> assign(:form, nil)
          |> assign(:error, "Reset link has expired. Please request a new password reset.")
          |> assign(:success, nil)
          |> assign(:loading, false)

        {:ok, socket}

      {:error, :account_deactivated} ->
        socket =
          socket
          |> assign(:token, nil)
          |> assign(:user, nil)
          |> assign(:form, nil)
          |> assign(:error, "This account has been deactivated. Please contact support.")
          |> assign(:success, nil)
          |> assign(:loading, false)

        {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Reset Your Password
          </h2>
          <p :if={@user} class="mt-2 text-center text-sm text-gray-600">
            Enter your new password for <%= @user.email %>
          </p>
        </div>

        <!-- Error Message -->
        <div :if={@error} class="bg-red-50 border border-red-200 rounded-md p-4">
          <div class="flex">
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">
                <%= @error %>
              </h3>
            </div>
          </div>
        </div>

        <!-- Success Message -->
        <div :if={@success} class="bg-green-50 border border-green-200 rounded-md p-4">
          <div class="flex">
            <div class="ml-3">
              <h3 class="text-sm font-medium text-green-800">
                <%= @success %>
              </h3>
            </div>
          </div>
        </div>

        <!-- Reset Form -->
        <div :if={@token && @user && !@success} class="mt-8 space-y-6">
          <.form for={@form} phx-submit="reset_password" class="space-y-6">
            <div>
              <label for="password" class="block text-sm font-medium text-gray-700">
                New Password
              </label>
              <div class="mt-1">
                <.input
                  field={@form[:password]}
                  type="password"
                  required
                  class="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  placeholder="Enter your new password"
                />
              </div>
              <p class="mt-1 text-xs text-gray-500">
                Must be at least 8 characters with uppercase, lowercase, and number
              </p>
            </div>

            <div>
              <label for="password_confirmation" class="block text-sm font-medium text-gray-700">
                Confirm New Password
              </label>
              <div class="mt-1">
                <.input
                  field={@form[:password_confirmation]}
                  type="password"
                  required
                  class="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  placeholder="Confirm your new password"
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
                <%= if @loading, do: "Resetting Password...", else: "Reset Password" %>
              </button>
            </div>
          </.form>
        </div>

        <div :if={@success} class="text-center">
          <.link navigate={~p"/auth"} class="text-indigo-600 hover:text-indigo-800 hover:underline transition-colors">
            Go to Login
          </.link>
        </div>

        <div :if={@error} class="text-center">
          <.link navigate={~p"/forgot_password"} class="text-indigo-600 hover:text-indigo-800 hover:underline transition-colors">
            Request New Reset Link
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("reset_password", %{"password" => password, "password_confirmation" => password_confirmation}, socket) do
    socket = assign(socket, :loading, true)

    cond do
      password != password_confirmation ->
        {:noreply,
         socket
         |> assign(:error, "Passwords do not match")
         |> assign(:loading, false)}

      String.length(password) < 8 ->
        {:noreply,
         socket
         |> assign(:error, "Password must be at least 8 characters long")
         |> assign(:loading, false)}

      not String.match?(password, ~r/[A-Z]/) ->
        {:noreply,
         socket
         |> assign(:error, "Password must contain at least one uppercase letter")
         |> assign(:loading, false)}

      not String.match?(password, ~r/[a-z]/) ->
        {:noreply,
         socket
         |> assign(:error, "Password must contain at least one lowercase letter")
         |> assign(:loading, false)}

      not String.match?(password, ~r/[0-9]/) ->
        {:noreply,
         socket
         |> assign(:error, "Password must contain at least one number")
         |> assign(:loading, false)}

      true ->
        case Accounts.reset_password(socket.assigns.token, password) do
          {:ok, _user} ->
            {:noreply,
             socket
             |> assign(:success, "Password reset successfully! You can now log in with your new password.")
             |> assign(:error, nil)
             |> assign(:loading, false)}

          {:error, %Ecto.Changeset{} = changeset} ->
            errors = extract_changeset_errors(changeset)
            {:noreply,
             socket
             |> assign(:error, Enum.join(errors, ", "))
             |> assign(:loading, false)}

          {:error, :invalid_token} ->
            {:noreply,
             socket
             |> assign(:error, "Reset link is no longer valid. Please request a new password reset.")
             |> assign(:loading, false)}

          {:error, :expired_token} ->
            {:noreply,
             socket
             |> assign(:error, "Reset link has expired. Please request a new password reset.")
             |> assign(:loading, false)}

          {:error, _} ->
            {:noreply,
             socket
             |> assign(:error, "Could not reset password. Please try again.")
             |> assign(:loading, false)}
        end
    end
  end

  # Helper function to extract changeset errors
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

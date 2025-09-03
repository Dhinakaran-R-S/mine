defmodule PrzmaWeb.OTPVerifyLive do
  use PrzmaWeb, :live_view
  alias Przma.Accounts
  alias Przma.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, otp_code: "", error: nil, user_id: nil, success_message: nil)}
  end

  @impl true
  def handle_params(%{"user_id" => user_id}, _uri, socket) do
    case Accounts.get_user(user_id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "User not found")
         |> push_navigate(to: ~p"/auth")}

      %User{is_verified: true} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account already verified. You can login now.")
         |> push_navigate(to: ~p"/auth")}

      user ->
        {:noreply, assign(socket, user_id: user_id, user: user)}
    end
  end

  @impl true
  def handle_event("submit_otp", %{"otp_code" => otp_code}, socket) do
    user_id = socket.assigns.user_id

    case Accounts.verify_otp(user_id, otp_code) do
      {:ok, user} ->
        # Mark OTP as used and verify the user
        case Accounts.mark_otp_used(user) do
          {:ok, _updated_user} ->
            case Accounts.verify_user(user) do
              {:ok, _verified_user} ->
                {:noreply,
                 socket
                 |> put_flash(:info, "Email verified successfully! You can now login.")
                 |> push_navigate(to: ~p"/auth")}

              {:error, _changeset} ->
                {:noreply,
                 socket
                 |> assign(:error, "Failed to verify account. Please try again.")
                 |> assign(:success_message, nil)}
            end

          {:error, _changeset} ->
            {:noreply,
             socket
             |> assign(:error, "Failed to process OTP. Please try again.")
             |> assign(:success_message, nil)}
        end

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:error, reason)
         |> assign(:success_message, nil)}
    end
  end

  @impl true
  def handle_event("resend_otp", _params, socket) do
    user_id = socket.assigns.user_id

    case Accounts.get_user(user_id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "User not found")
         |> push_navigate(to: ~p"/auth")}

      %User{is_verified: true} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account already verified")
         |> push_navigate(to: ~p"/auth")}

      user ->
        case Accounts.resend_otp(user) do
          {:ok, _updated_user} ->
            {:noreply,
             socket
             |> assign(:success_message, "New OTP sent to your email. Please check your inbox.")
             |> assign(:error, nil)}

          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(:error, "Failed to resend OTP. Please try again later.")
             |> assign(:success_message, nil)}
        end
    end
  end

  @impl true
  def handle_event("otp_input_change", %{"otp_code" => otp_code}, socket) do
    {:noreply, assign(socket, otp_code: otp_code)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 p-6">
      <div class="w-full max-w-md bg-white rounded-lg shadow-md p-8">
        <div class="text-center mb-6">
          <h2 class="text-2xl font-semibold text-gray-800">Verify Your Email</h2>
          <p class="text-sm text-gray-600 mt-2">
            We've sent a verification code to your email address
          </p>
        </div>

        <!-- Success Message -->
        <%= if @success_message do %>
          <div class="mb-4 p-4 bg-green-50 border border-green-200 rounded-md">
            <p class="text-sm text-green-800"><%= @success_message %></p>
          </div>
        <% end %>

        <!-- Error Message -->
        <%= if @error do %>
          <div class="mb-4 p-4 bg-red-50 border border-red-200 rounded-md">
            <p class="text-sm text-red-600 font-medium text-center"><%= @error %></p>
          </div>
        <% end %>

        <!-- OTP Input Form -->
        <form phx-submit="submit_otp" class="space-y-4">
          <div>
            <label for="otp_code" class="block text-sm font-medium text-gray-700 mb-2">
              Enter 6-digit verification code
            </label>
            <input
              type="text"
              name="otp_code"
              id="otp_code"
              value={@otp_code}
              phx-change="otp_input_change"
              placeholder="000000"
              maxlength="6"
              pattern="[0-9]{6}"
              autofocus
              autocomplete="one-time-code"
              class="w-full px-4 py-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-lg text-center tracking-widest"
            />
          </div>

          <button
            type="submit"
            class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 rounded-md transition duration-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          >
            Verify Email
          </button>
        </form>

        <!-- Resend OTP Section -->
        <div class="mt-6 text-center">
          <p class="text-sm text-gray-600 mb-3">
            Didn't receive the code?
          </p>
          <button
            phx-click="resend_otp"
            class="w-full bg-gray-100 hover:bg-gray-200 text-gray-800 font-semibold py-2 rounded-md transition duration-300 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"
          >
            Resend Verification Code
          </button>
        </div>

        <!-- Back to Login -->
        <div class="mt-6 text-center">
          <a
            href={~p"/auth"}
            class="text-indigo-600 hover:text-indigo-500 text-sm font-medium"
          >
            ← Back to Login
          </a>
        </div>
      </div>
    </div>
    """
  end
end

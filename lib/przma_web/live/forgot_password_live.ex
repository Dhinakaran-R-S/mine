# lib/przma_web/live/forgot_password_live.ex

defmodule PrzmaWeb.ForgotPasswordLive do
  use PrzmaWeb, :live_view
  require Logger
  alias Przma.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:form, to_form(Accounts.change_forgot_password_email(), as: "user"))
      |> assign(:message, nil)
      |> assign(:is_error, false)
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
            Forgot Your Password?
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            Enter your email address and we'll send you a link to reset your password.
          </p>
        </div>

        <!-- Success/Error Message -->
        <div :if={@message} class={[
          "rounded-md p-4",
          if(@is_error, do: "bg-red-50 border border-red-200", else: "bg-green-50 border border-green-200")
        ]}>
          <div class="flex">
            <div class="ml-3">
              <p class={[
                "text-sm font-medium",
                if(@is_error, do: "text-red-800", else: "text-green-800")
              ]}>
                <%= @message %>
              </p>
            </div>
          </div>
        </div>

        <div class="mt-8 space-y-6">
          <.form for={@form} phx-submit="send_reset" class="space-y-6">
            <div>
              <label for="email" class="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <div class="mt-1">
                <.input
                  field={@form[:email]}
                  type="email"
                  required
                  class="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  placeholder="Enter your email address"
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
                <%= if @loading, do: "Sending...", else: "Send Reset Link" %>
              </button>
            </div>
          </.form>

          <div class="text-center">
            <.link navigate={~p"/auth"} class="text-indigo-600 hover:text-indigo-800 hover:underline transition-colors">
              Back to Login
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("send_reset", %{"user" => %{"email" => email}}, socket) do
    Logger.info("Password reset requested for: #{email}")

    socket = assign(socket, :loading, true)

    case Accounts.initiate_password_reset(email) do
      {:ok, :email_sent} ->
        {:noreply,
         socket
         |> assign(:message, "If this email exists in our system, a reset link has been sent.")
         |> assign(:is_error, false)
         |> assign(:loading, false)}

      {:error, :account_deactivated} ->
        {:noreply,
         socket
         |> assign(:message, "This account has been deactivated. Please contact support.")
         |> assign(:is_error, true)
         |> assign(:loading, false)}

      {:error, :email_failed} ->
        {:noreply,
         socket
         |> assign(:message, "Failed to send email. Please try again later.")
         |> assign(:is_error, true)
         |> assign(:loading, false)}

      {:error, :token_generation_failed} ->
        {:noreply,
         socket
         |> assign(:message, "Failed to generate reset token. Please try again.")
         |> assign(:is_error, true)
         |> assign(:loading, false)}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:message, "An unexpected error occurred. Please try again.")
         |> assign(:is_error, true)
         |> assign(:loading, false)}
    end
  end
end

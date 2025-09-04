defmodule PrzmaWeb.Plugs.RequireAuth do
  @moduledoc """
  Plug to require authentication for any user.
  """

  def init(opts), do: opts

  def call(conn, _opts) do
    PrzmaWeb.Plugs.AuthPlug.call(conn, [])
  end
end



# lib/przma_web/plugs/require_admin.ex
defmodule PrzmaWeb.Plugs.RequireAdmin do
  @moduledoc """
  Plug to require superadmin role.
  """

  def init(opts), do: opts

  def call(conn, _opts) do
    PrzmaWeb.Plugs.AuthPlug.call(conn, [role: "superadmin"])
  end
end

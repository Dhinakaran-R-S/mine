defmodule Przma.Sessions do
  import Ecto.Query, warn: false
  alias Przma.Repo
  alias Przma.Sessions.Session

  def create_session(attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  def list_sessions do
    Repo.all(Session)
  end
end

defmodule Supermarket.Accounts do
  # import Ecto.Query
  alias Supermarket.{Repo}
  alias Supermarket.Accounts.User

  # Registro
  def register_user(%{username: u, password: p, password_confirmation: pc}) do
    %User{}
    |> User.registration_changeset(%{username: u, password: p, password_confirmation: pc})
    |> Repo.insert()
  end

  # Login (autenticación)
  def authenticate(username, password) do
    case Repo.get_by(User, username: username) do
      nil -> {:error, :not_found}
      %User{password_hash: phash} ->
        if secure_check?(phash, password), do: {:ok, :authenticated}, else: {:error, :invalid_password}
    end
  end

  # ===== util =====
  defp secure_check?(stored_hash, password) do
    salt = "supermarket_salt_v1"
    computed =
      :crypto.hash(:sha256, salt <> password)
      |> Base.encode16(case: :lower)

    # comparación en tiempo “constante” básico
    Plug.Crypto.secure_compare(stored_hash, computed)
  end
end

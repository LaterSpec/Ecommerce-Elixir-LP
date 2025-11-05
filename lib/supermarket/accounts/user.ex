defmodule Supermarket.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string
    timestamps()
  end

  # registro con password plano (se hashea aquí)
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :password_confirmation])
    |> validate_required([:username, :password, :password_confirmation])
    |> validate_length(:username, min: 3, max: 40)
    |> validate_length(:password, min: 4, max: 72)
    |> validate_confirmation(:password, message: "no coincide")
    |> unique_constraint(:username)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    # Hash simple con SHA256 + sal; suficiente para trabajo de curso
    salt = "supermarket_salt_v1"
    hash =
      :crypto.hash(:sha256, salt <> pw)
      |> Base.encode16(case: :lower)

    put_change(cs, :password_hash, hash)
  end

  defp put_password_hash(cs), do: cs
end

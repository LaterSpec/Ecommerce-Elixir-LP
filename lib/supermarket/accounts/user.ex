defmodule Supermarket.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    # Campo nuevo para saber si es admin o user
    field :role, :string, default: "user"
    
    # :password es virtual, solo existe en el formulario
    field :password, :string, virtual: true 
    field :password_hash, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    # Agregamos :role aqui por si algun dia queremos editarlo desde un panel de admin
    user
    |> cast(attrs, [:username, :password_hash, :role])
    |> validate_required([:username, :password_hash, :role])
  end

  @doc """
  Changeset para registro publico.
  NO permitimos que el usuario elija su rol aqui (siempre sera 'user' por defecto).
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required([:username, :password])
    |> validate_length(:password, min: 6, message: "must be at least 6 chars")
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil -> 
        changeset
      password ->
        # SHA-256 ENCRYPTION
        hash = :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)
        put_change(changeset, :password_hash, hash)
    end
  end
end
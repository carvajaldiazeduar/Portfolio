defmodule PasswordGenerator.PasswordsService do
  @moduledoc """
  Service layer for stored passwords: cache-first reads with DB fallback.
  Writes invalidate the `passwords:all` cache key.
  """

  alias PasswordGenerator.{Cache, PasswordEntry, Repo}
  import Ecto.Query

  def list_all(ttl \\ default_ttl()) do
    case Cache.get("passwords:all") do
      {:ok, entries} -> entries
      :error ->
        entries = Repo.all(from e in PasswordEntry, order_by: e.id)
        Cache.set("passwords:all", entries, ttl)
        entries
    end
  end

  def create(attrs) do
    changeset = PasswordEntry.changeset(%PasswordEntry{}, attrs)

    if changeset.valid? do
      case Repo.insert(changeset) do
        {:ok, entry} ->
          invalidate_all()
          {:ok, entry}

        {:error, changeset} ->
          {:error, PasswordEntry.error_map(changeset)}
      end
    else
      {:error, PasswordEntry.error_map(changeset)}
    end
  end

  def delete(id) do
    case Repo.get(PasswordEntry, id) do
      nil ->
        {:error, :not_found}

      entry ->
        Repo.delete(entry)
        invalidate_all()
        {:ok, entry}
    end
  end

  defp invalidate_all do
    Cache.delete("passwords:all")
  end

  defp default_ttl do
    Application.get_env(:password_generator, :cache_ttl, 300)
  end
end
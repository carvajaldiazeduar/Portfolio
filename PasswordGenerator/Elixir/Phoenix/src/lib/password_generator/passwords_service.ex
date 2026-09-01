defmodule PasswordGenerator.PasswordsService do
  alias PasswordGenerator.{Cache, PasswordEntry, Repo}

  def list_all do
    case Cache.get("passwords:all") do
      nil ->
        entries = Repo.all(PasswordEntry)
        Cache.put("passwords:all", Enum.map(entries, &PasswordEntry.to_dto/1))

      entries ->
        entries
    end
  end

  def create(attrs) do
    case Repo.insert(PasswordEntry.changeset(%PasswordEntry{}, attrs)) do
      {:ok, entry} ->
        Cache.delete("passwords:all")
        {:ok, PasswordEntry.to_dto(entry)}

      {:error, changeset} ->
        {:error, validation_errors(changeset)}
    end
  end

  def delete(id) do
    case Repo.get(PasswordEntry, id) do
      nil ->
        {:error, :not_found}

      entry ->
        case Repo.delete(entry) do
          {:ok, deleted} ->
            Cache.delete("passwords:all")
            {:ok, deleted}

          error ->
            error
        end
    end
  end

  defp validation_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
    |> Map.new(fn {field, [message | _]} -> {Atom.to_string(field), message} end)
  end
end

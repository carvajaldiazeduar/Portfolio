defmodule Contacts.ContactsService do
  @moduledoc """
  Service layer for contacts: cache-first reads with DB fallback.
  Writes invalidate the relevant cache keys.
  """

  alias Contacts.{Cache, Contact, Repo}
  import Ecto.Query

  def list_all(ttl \\ default_ttl()) do
    case Cache.get("contacts:all") do
      {:ok, contacts} -> contacts
      :error ->
        contacts = Repo.all(from c in Contact, order_by: c.id)
        Cache.set("contacts:all", contacts, ttl)
        contacts
    end
  end

  def search(q, ttl \\ default_ttl()) do
    key = "contacts:search:#{q}"

    case Cache.get(key) do
      {:ok, results} ->
        results

      :error ->
        q = String.downcase(q)
        query = from c in Contact, where: like(c.name, ^"%#{q}%"), order_by: c.id
        results = Repo.all(query)
        Cache.set(key, results, ttl)
        results
    end
  end

  def show(id) do
    case Repo.get(Contact, id) do
      nil -> :error
      contact -> {:ok, contact}
    end
  end

  def create(attrs) do
    changeset = Contact.changeset(%Contact{}, attrs)

    if changeset.valid? do
      case Repo.insert(changeset) do
        {:ok, contact} ->
          invalidate_all()
          {:ok, contact}

        {:error, changeset} ->
          {:error, Contact.error_map(changeset)}
      end
    else
      {:error, Contact.error_map(changeset)}
    end
  end

  def update(id, attrs) do
    case Repo.get(Contact, id) do
      nil ->
        {:error, :not_found}

      contact ->
        changeset = Contact.changeset(contact, attrs)

        if changeset.valid? do
          case Repo.update(changeset) do
            {:ok, contact} ->
              invalidate_all()
              {:ok, contact}

            {:error, changeset} ->
              {:error, Contact.error_map(changeset)}
          end
        else
          {:error, Contact.error_map(changeset)}
        end
    end
  end

  def delete(id) do
    case Repo.get(Contact, id) do
      nil ->
        {:error, :not_found}

      contact ->
        Repo.delete(contact)
        invalidate_all()
        {:ok, contact}
    end
  end

  defp invalidate_all do
    Cache.delete("contacts:all")
  end

  defp default_ttl do
    Application.get_env(:contacts, :cache_ttl, 300)
  end
end
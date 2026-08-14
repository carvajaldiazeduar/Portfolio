defmodule Contacts.CLI do
  @moduledoc """
  Interactive contacts manager CLI (escript entry point).
  """

  alias Contacts, as: Contacts

  def main(_args) do
    contacts = []
    loop(contacts)
  end

  defp loop(contacts) do
    IO.puts("\n── CONTACTS MENU ──")
    IO.puts("1. Add contact")
    IO.puts("2. Search contact")
    IO.puts("3. Delete contact")
    IO.puts("4. List all")
    IO.puts("5. Exit")

    case read_int("Choose an option") do
      1 -> loop(add(contacts))
      2 -> loop(search(contacts))
      3 -> loop(delete(contacts))
      4 -> loop(list(contacts))
      5 -> IO.puts("Goodbye!")
      _ ->
        IO.puts("Invalid option")
        loop(contacts)
    end
  end

  defp add(contacts) do
    name = read_line("name")
    phone = read_line("phone")
    email = read_line("email")

    case Contacts.create(contacts, name, phone, email) do
      {:ok, contact} ->
        IO.puts("Contact added! (#{contact.name})")
        [contact | contacts]

      {:error, errors} ->
        Enum.each(errors, &IO.puts/1)
        contacts
    end
  end

  defp search(contacts) do
    query = read_line("search query")
    results = Contacts.search(contacts, query)

    if results == [] do
      IO.puts("No contacts found.")
    else
      Enum.each(results, fn c ->
        IO.puts("#{c.name} | #{c.phone} | #{c.email}")
      end)
    end

    contacts
  end

  defp delete(contacts) do
    id = read_int("contact id to delete")
    case Contacts.delete(contacts, id) do
      {:ok, contact} ->
        IO.puts("Contact deleted! (#{contact.name})")
        Enum.reject(contacts, &(&1.id == id))

      {:error, :not_found} ->
        IO.puts("Contact not found.")
        contacts
    end
  end

  defp list(contacts) do
    case Contacts.list(contacts) do
      [] -> IO.puts("No contacts found.")
      list ->
        Enum.each(list, fn c ->
          IO.puts("#{c.id}. #{c.name} | #{c.phone} | #{c.email}")
        end)
    end

    contacts
  end

  defp read_line(prompt) do
    IO.gets("#{prompt}: ") |> String.trim()
  end

  defp read_int(prompt) do
    case Integer.parse(IO.gets("#{prompt}: ")) do
      {n, _} -> n
      :error -> -1
    end
  end
end
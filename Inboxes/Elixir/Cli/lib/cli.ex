defmodule Inboxes.CLI do
  @moduledoc """
  Interactive inbox CLI (escript entry point).
  """

  alias Inboxes

  def main(_args) do
    loop([])
  end

  defp loop(messages) do
    IO.puts("\n=== Inbox CLI ===")
    IO.puts("1. Send message")
    IO.puts("2. List messages")
    IO.puts("3. Read message")
    IO.puts("4. Delete message")
    IO.puts("5. Exit")

    case read_int("Choice") do
      1 -> loop(send_message(messages))
      2 -> loop(list(messages))
      3 -> loop(read(messages))
      4 -> loop(delete(messages))
      5 -> IO.puts("Goodbye!")
      _ ->
        IO.puts("Invalid choice")
        loop(messages)
    end
  end

  defp send_message(messages) do
    from = read_line("From")
    subject = read_line("Subject")
    body = read_line("Body")
    {:ok, message} = Inboxes.send_message(messages, from, subject, body)
    IO.puts("Message sent (id=#{message.id})")
    [message | messages]
  end

  defp list(messages) do
    case Inboxes.list_messages(messages) do
      [] ->
        IO.puts("No messages.")

      list ->
        Enum.each(list, fn m ->
          status = if m.read, do: "R", else: "U"
          IO.puts("[#{m.id}] #{status} From: #{m.from} | Subject: #{m.subject} | #{m.created_at}")
        end)
    end

    messages
  end

  defp read(messages) do
    id = read_int("Message ID")

    case Inboxes.read_message(messages, id) do
      {:ok, m} ->
        IO.puts("From: #{m.from}")
        IO.puts("Subject: #{m.subject}")
        IO.puts("Date: #{m.created_at}")
        IO.puts("---")
        IO.puts(m.body)

        Enum.map(messages, fn msg ->
          if msg.id == id, do: %{msg | read: true}, else: msg
        end)

      {:error, :not_found} ->
        IO.puts("Message not found.")
        messages
    end
  end

  defp delete(messages) do
    id = read_int("Message ID")

    case Inboxes.delete_message(messages, id) do
      {:ok, _} ->
        IO.puts("Message deleted.")
        Enum.reject(messages, &(&1.id == id))

      {:error, :not_found} ->
        IO.puts("Message not found.")
        messages
    end
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
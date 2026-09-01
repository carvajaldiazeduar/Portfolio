defmodule Inboxes.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :sender, :string
    field :subject, :string
    field :body, :string
    field :read, :boolean, default: false

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:sender, :subject, :body, :read])
    |> validate_required(:sender, message: "Sender is required")
    |> validate_required(:subject, message: "Subject is required")
    |> validate_required(:body, message: "Body is required")
  end

  def to_dto(%__MODULE__{} = message) do
    %{
      id: message.id,
      sender: message.sender,
      from: message.sender,
      subject: message.subject,
      body: message.body,
      read: message.read
    }
  end
end

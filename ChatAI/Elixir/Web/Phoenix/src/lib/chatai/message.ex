defmodule ChatAI.Message do
  @moduledoc """
  A single chat message: role + content.
  """
  @enforce_keys [:role, :content]
  defstruct [:role, :content]

  @type t :: %__MODULE__{role: String.t(), content: String.t()}

  def from_map(%{"role" => role, "content" => content}) when is_binary(content),
    do: %__MODULE__{role: role, content: content}

  def from_map(%{"role" => role, "content" => content}) when is_list(content) do
    text =
      content
      |> Enum.map(fn
        %{"text" => t} -> t
        t when is_binary(t) -> t
        _ -> ""
      end)
      |> Enum.join()

    %__MODULE__{role: role, content: text}
  end

  def from_map(%{role: role, content: content}) when is_binary(content),
    do: %__MODULE__{role: role, content: content}

  def from_map(_), do: nil
end

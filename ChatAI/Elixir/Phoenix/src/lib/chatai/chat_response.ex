defmodule ChatAI.ChatResponse do
  @moduledoc """
  Normalized assistant response shared by all providers.
  """
  defstruct [:id, :provider, :model, choices: [], usage: %{}]

  @type t :: %__MODULE__{
          id: String.t(),
          provider: String.t(),
          model: String.t(),
          choices: [map],
          usage: map
        }

  def empty_choice do
    %{role: "assistant", content: ""}
  end

  def to_map(%__MODULE__{} = resp) do
    %{
      id: resp.id,
      provider: resp.provider,
      model: resp.model,
      choices: resp.choices,
      usage: resp.usage
    }
  end
end

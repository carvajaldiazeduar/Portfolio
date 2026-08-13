defmodule Contacts do
  @moduledoc """
  Contact management core: validation, add, list, search, update and delete
  in-memory contacts.

  Mirrors the Ruby and Node CLI behaviour:

  - name: required, 2..100 chars, letters/spaces/apostrophes/hyphens/dots
  - phone: required, 7..20 chars, digits/spaces/+/(/)/dashes
  - email: required, matches `user@domain.tld`

  Return style:
    {:ok, contact}   on success
    {:error, msg}    on failure (msg string)
  """

  @name_re ~r/\A[A-Za-zÀ-ÿ' .-]+\z/
  @phone_re ~r/\A[0-9 +().-]{7,20}\z/
  @email_re ~r/\A[^\s@]+@[^\s@]+\.[^\s@]{2,}\z/

  defstruct [:id, :name, :phone, :email]

  @type t :: %__MODULE__{id: pos_integer, name: String.t(), phone: String.t(), email: String.t()}

  @spec validate(name :: String.t(), phone :: String.t(), email :: String.t()) :: [String.t()]
  def validate(name, phone, email) do
    []
    |> maybe_name_error(name)
    |> maybe_phone_error(phone)
    |> maybe_email_error(email)
  end

  defp maybe_name_error(errors, name) do
    cond do
      name == "" -> ["Name is required" | errors]
      String.length(name) < 2 or String.length(name) > 100 ->
        ["Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)" | errors]
      not Regex.match?(@name_re, name) ->
        ["Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)" | errors]
      true -> errors
    end
  end

  defp maybe_phone_error(errors, phone) do
    cond do
      phone == "" -> ["Phone is required" | errors]
      not Regex.match?(@phone_re, phone) ->
        ["Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)" | errors]
      true -> errors
    end
  end

  defp maybe_email_error(errors, email) do
    cond do
      email == "" -> ["Email is required" | errors]
      not Regex.match?(@email_re, email) -> ["Invalid email format" | errors]
      true -> errors
    end
  end

  @spec create([t()], String.t(), String.t(), String.t()) ::
          {:ok, t()} | {:error, [String.t()]}
  def create(contacts, name, phone, email) do
    case validate(name, phone, email) do
      [] ->
        id = (Enum.map(contacts, & &1.id) |> Enum.max(fn -> 0 end)) + 1
        {:ok, %__MODULE__{id: id, name: name, phone: phone, email: email}}

      errors ->
        {:error, errors}
    end
  end

  @spec list([t()]) :: [t()]
  def list(contacts), do: contacts

  @spec search([t()], String.t()) :: [t()]
  def search(contacts, query) do
    q = String.downcase(query)
    Enum.filter(contacts, &String.contains?(String.downcase(&1.name), q))
  end

  @spec update([t()], pos_integer, String.t(), String.t(), String.t()) ::
          {:ok, t()} | {:error, [String.t()]} | {:error, :not_found}
  def update(contacts, id, name, phone, email) do
    if Enum.any?(contacts, &(&1.id == id)) do
      case validate(name, phone, email) do
        [] -> {:ok, %__MODULE__{id: id, name: name, phone: phone, email: email}}
        errors -> {:error, errors}
      end
    else
      {:error, :not_found}
    end
  end

  @spec delete([t()], pos_integer) :: {:ok, t()} | {:error, :not_found}
  def delete(contacts, id) do
    case Enum.find(contacts, &(&1.id == id)) do
      nil -> {:error, :not_found}
      contact -> {:ok, contact}
    end
  end
end
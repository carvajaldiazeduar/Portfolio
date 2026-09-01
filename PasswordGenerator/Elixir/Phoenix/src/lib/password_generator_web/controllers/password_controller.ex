defmodule PasswordGeneratorWeb.PasswordController do
  use PasswordGeneratorWeb, :controller

  alias PasswordGenerator.{Generator, PasswordsService}

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, Application.app_dir(:password_generator, "priv/static/index.html"))
  end

  def generate(conn, params) do
    length = param_int(params, "length", 16)
    upper = param_bool(params, "uppercase", true)
    lower = param_bool(params, "lowercase", true)
    digits = param_bool(params, "numbers", true)
    symbols = param_bool(params, "symbols", false)

    case Generator.generate(length, upper, lower, digits, symbols) do
      {:ok, password} -> json(conn, %{password: password})
      {:error, msg} -> error(conn, 400, %{errors: %{length: msg}})
    end
  end

  def list(conn, _params) do
    json(conn, PasswordsService.list_all())
  end

  def create(conn, params) do
    case PasswordsService.create(params) do
      {:ok, entry} ->
        conn
        |> put_status(:created)
        |> json(entry)

      {:error, errors} ->
        error(conn, 400, %{errors: errors})
    end
  end

  def delete(conn, %{"id" => id}) do
    case PasswordsService.delete(parse_id(id)) do
      {:ok, _entry} -> json(conn, %{result: "deleted"})
      {:error, :not_found} -> error(conn, 404, %{error: "Not found"})
    end
  end

  def swagger(conn, _params) do
    redirect(conn, to: "/swagger.html")
  end

  defp parse_id(id) do
    case Integer.parse(to_string(id)) do
      {int, _} -> int
      :error -> id
    end
  end

  defp param_int(params, key, default) do
    case Map.get(params, key) do
      nil -> default
      value -> case Integer.parse(to_string(value)) do
        {int, _} -> int
        :error -> default
      end
    end
  end

  defp param_bool(params, key, default) do
    case Map.get(params, key) do
      nil -> default
      "true" -> true
      "false" -> false
      _ -> default
    end
  end

  defp error(conn, status, payload) do
    conn
    |> put_status(status)
    |> json(payload)
  end
end
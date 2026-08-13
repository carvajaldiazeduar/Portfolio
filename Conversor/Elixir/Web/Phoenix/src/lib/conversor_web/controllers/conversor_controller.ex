defmodule ConversorWeb.ConversorController do
  use ConversorWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, Application.app_dir(:conversor, "priv/static/index.html"))
  end

  def categories(conn, _params) do
    json(conn, Conversor.category_units())
  end

  def convert(conn, %{"value" => value, "from" => from, "to" => to}) do
    value = parse_number(value)

    if is_nil(value) or from == "" or to == "" do
      error(conn, 400, "Missing fields: value, from, to")
    else
      case Conversor.convert(value, from, to) do
        {:ok, result} -> json(conn, %{result: result, from: from, to: to, value: value})
        {:error, message} -> error(conn, 400, message)
      end
    end
  end

  def convert(conn, _params) do
    error(conn, 400, "Missing fields: value, from, to")
  end

  def swagger(conn, _params) do
    redirect(conn, to: "/swagger.html")
  end

  defp parse_number(value) when is_number(value), do: value

  defp parse_number(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _ -> nil
    end
  end

  defp parse_number(_), do: nil

  defp error(conn, status, message) do
    conn
    |> put_status(status)
    |> json(%{error: message})
  end
end
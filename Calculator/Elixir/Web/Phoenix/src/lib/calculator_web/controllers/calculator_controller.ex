defmodule CalculatorWeb.CalculatorController do
  use CalculatorWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, Application.app_dir(:calculator, "priv/static/index.html"))
  end

  def calculate(conn, %{"a" => a, "b" => b, "operator" => operator} = _params) do
    a = parse_number(a)
    b = parse_number(b)

    cond do
      is_nil(a) or is_nil(b) ->
        error(conn, 400, "Invalid number input")

      operator not in Calculator.allowed_operators() ->
        error(conn, 400, "Invalid operator")

      true ->
        case Calculator.calculate(a, b, operator) do
          {:ok, result} -> json(conn, %{result: result})
          {:error, message} -> error(conn, 400, message)
        end
    end
  end

  def calculate(conn, _params) do
    error(conn, 400, "Invalid number input")
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

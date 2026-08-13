defmodule ConversorWeb.ConversorControllerTest do
  use ConversorWeb.ConnCase, async: true

  test "GET /api/categories returns categories with units", %{conn: conn} do
    conn = get(conn, "/api/categories")

    assert json_response(conn, 200) == %{
             "length" => ["m", "km", "mi", "ft", "in", "cm"],
             "weight" => ["kg", "g", "lb", "oz", "mg"],
             "temperature" => ["C", "F", "K"]
           }
  end

  test "POST /api/convert converts length", %{conn: conn} do
    conn = post(conn, "/api/convert", %{value: 1, from: "km", to: "m"})

    assert %{"result" => result, "from" => "km", "to" => "m", "value" => 1} =
             json_response(conn, 200)

    assert_in_delta result, 1000.0, 0.0001
  end

  test "POST /api/convert converts temperature", %{conn: conn} do
    conn = post(conn, "/api/convert", %{value: 0, from: "C", to: "F"})

    assert %{"result" => 32.0, "from" => "C", "to" => "F"} = json_response(conn, 200)
  end

  test "POST /api/convert rejects incompatible units", %{conn: conn} do
    conn = post(conn, "/api/convert", %{value: 1, from: "m", to: "kg"})

    assert json_response(conn, 400) == %{"error" => "Incompatible units"}
  end

  test "POST /api/convert rejects missing fields", %{conn: conn} do
    conn = post(conn, "/api/convert", %{value: 1})

    assert json_response(conn, 400) == %{"error" => "Missing fields: value, from, to"}
  end

  test "GET /swagger redirects", %{conn: conn} do
    conn = get(conn, "/swagger")
    assert redirected_to(conn, 302) == "/swagger.html"
  end
end
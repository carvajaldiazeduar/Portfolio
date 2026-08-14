defmodule CalculatorWeb.CalculatorControllerTest do
  use CalculatorWeb.ConnCase, async: true

  describe "POST /calculate" do
    test "adds two numbers", %{conn: conn} do
      conn = post(conn, "/calculate", %{a: 2, b: 3, operator: "add"})

      assert json_response(conn, 200) == %{"result" => 5.0}
    end

    test "subtracts two numbers", %{conn: conn} do
      conn = post(conn, "/calculate", %{a: 10, b: 4, operator: "subtract"})

      assert json_response(conn, 200) == %{"result" => 6.0}
    end

    test "multiplies two numbers", %{conn: conn} do
      conn = post(conn, "/calculate", %{a: 6, b: 7, operator: "multiply"})

      assert json_response(conn, 200) == %{"result" => 42.0}
    end

    test "divides two numbers", %{conn: conn} do
      conn = post(conn, "/calculate", %{a: 10, b: 4, operator: "divide"})

      assert json_response(conn, 200) == %{"result" => 2.5}
    end

    test "rejects division by zero", %{conn: conn} do
      conn = post(conn, "/calculate", %{a: 10, b: 0, operator: "divide"})

      assert json_response(conn, 400) == %{"error" => "Cannot divide by zero"}
    end

    test "rejects invalid operator", %{conn: conn} do
      conn = post(conn, "/calculate", %{a: 10, b: 4, operator: "modulo"})

      assert json_response(conn, 400) == %{"error" => "Invalid operator"}
    end

    test "rejects non numeric input", %{conn: conn} do
      conn = post(conn, "/calculate", %{a: "abc", b: 4, operator: "add"})

      assert json_response(conn, 400) == %{"error" => "Invalid number input"}
    end

    test "rejects missing params", %{conn: conn} do
      conn = post(conn, "/calculate", %{a: 1})

      assert json_response(conn, 400) == %{"error" => "Invalid number input"}
    end
  end
end

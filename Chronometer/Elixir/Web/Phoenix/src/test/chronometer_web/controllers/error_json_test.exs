defmodule ChronometerWeb.ErrorJSONTest do
  use ChronometerWeb.ConnCase, async: true

  test "renders 404" do
    assert ChronometerWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ChronometerWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end

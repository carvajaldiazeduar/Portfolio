defmodule CalculatorWeb.Router do
  use CalculatorWeb, :router

  scope "/", CalculatorWeb do
    get "/", CalculatorController, :index
    post "/calculate", CalculatorController, :calculate
    get "/swagger", CalculatorController, :swagger
  end
end
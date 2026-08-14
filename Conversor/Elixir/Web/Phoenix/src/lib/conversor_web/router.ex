defmodule ConversorWeb.Router do
  use ConversorWeb, :router

  scope "/", ConversorWeb do
    get "/", ConversorController, :index
    get "/api/categories", ConversorController, :categories
    post "/api/convert", ConversorController, :convert
    get "/swagger", ConversorController, :swagger
  end
end
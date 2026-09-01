defmodule PasswordGeneratorWeb.Router do
  use PasswordGeneratorWeb, :router

  scope "/", PasswordGeneratorWeb do
    get "/", PasswordController, :index
    get "/api/generate", PasswordController, :generate
    get "/api/passwords", PasswordController, :list
    post "/api/passwords", PasswordController, :create
    delete "/api/passwords/:id", PasswordController, :delete
    get "/swagger", PasswordController, :swagger
  end
end
defmodule ContactsWeb.Router do
  use ContactsWeb, :router

  scope "/", ContactsWeb do
    get "/", ContactController, :index
    get "/api/contacts", ContactController, :list
    post "/api/contacts", ContactController, :create
    get "/api/contacts/search", ContactController, :search
    get "/api/contacts/:id", ContactController, :show
    put "/api/contacts/:id", ContactController, :update
    delete "/api/contacts/:id", ContactController, :delete
    get "/swagger", ContactController, :swagger
  end
end
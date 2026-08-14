defmodule InboxesWeb.Router do
  use InboxesWeb, :router

  scope "/", InboxesWeb do
    get "/", MessageController, :index
    get "/api/messages", MessageController, :list
    post "/api/messages", MessageController, :create
    get "/api/messages/:id", MessageController, :show
    delete "/api/messages/:id", MessageController, :delete
    get "/swagger", MessageController, :swagger
  end
end
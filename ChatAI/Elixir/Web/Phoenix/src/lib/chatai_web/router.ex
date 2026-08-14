defmodule ChatAIWeb.Router do
  use ChatAIWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ChatAIWeb do
    get "/", ChatController, :index
    get "/health", ChatController, :health
    get "/swagger", ChatController, :swagger
  end

  scope "/api", ChatAIWeb do
    pipe_through :api
    post "/chat", ChatController, :chat
  end
end

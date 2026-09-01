defmodule SemanticSearchWeb.Router do
  use SemanticSearchWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SemanticSearchWeb do
    get "/", DocumentController, :index
    get "/openapi.json", DocumentController, :openapi
    get "/swagger", DocumentController, :swagger
  end

  scope "/api", SemanticSearchWeb do
    pipe_through :api
    post "/upload", DocumentController, :upload
    get "/search", DocumentController, :search
    get "/collections", DocumentController, :collections
    delete "/collections/:name", DocumentController, :delete_collection
  end
end

defmodule TasksListWeb.Router do
  use TasksListWeb, :router

  scope "/", TasksListWeb do
    get "/", TaskController, :index
    get "/api/tasks", TaskController, :list
    post "/api/tasks", TaskController, :create
    get "/api/tasks/:id", TaskController, :show
    put "/api/tasks/:id", TaskController, :update
    delete "/api/tasks/:id", TaskController, :delete
    get "/swagger", TaskController, :swagger
  end
end
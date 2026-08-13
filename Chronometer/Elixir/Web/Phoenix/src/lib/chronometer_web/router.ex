defmodule ChronometerWeb.Router do
  use ChronometerWeb, :router

  scope "/", ChronometerWeb do
    get "/", TimerController, :index
    post "/start", TimerController, :start
    post "/pause", TimerController, :pause
    post "/resume", TimerController, :resume
    post "/reset", TimerController, :reset
    get "/status", TimerController, :status
    get "/swagger", TimerController, :swagger
  end
end
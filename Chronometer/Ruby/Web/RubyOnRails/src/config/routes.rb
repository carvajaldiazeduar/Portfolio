Rails.application.routes.draw do
  get "/swagger", to: redirect("/swagger.html")
  root "timer#index"

  post "start", to: "timer#start"
  post "stop", to: "timer#stop"
  post "reset", to: "timer#reset"
  post "lap", to: "timer#lap"
end
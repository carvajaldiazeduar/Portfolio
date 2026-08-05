Rails.application.routes.draw do
  root "timer#index"

  post "start", to: "timer#start"
  post "stop", to: "timer#stop"
  post "reset", to: "timer#reset"
  post "lap", to: "timer#lap"
end
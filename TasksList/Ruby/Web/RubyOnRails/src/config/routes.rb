Rails.application.routes.draw do
  root "tasks#index"

  resources :tasks, only: [:create, :destroy]
  put "tasks/:id/complete", to: "tasks#complete"
end

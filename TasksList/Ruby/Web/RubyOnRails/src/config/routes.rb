Rails.application.routes.draw do
  get "/swagger", to: redirect("/swagger.html")
  root "tasks#index"

  resources :tasks, only: [:create, :destroy]
  put "tasks/:id/complete", to: "tasks#complete"
end

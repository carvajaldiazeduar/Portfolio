Rails.application.routes.draw do
  get "/swagger", to: redirect("/swagger.html")
  root "messages#index"

  get  "messages/search", to: "messages#search"
  resources :messages, only: [:show, :create, :destroy]
end
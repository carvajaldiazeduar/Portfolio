Rails.application.routes.draw do
  root "messages#index"

  get  "messages/search", to: "messages#search"
  resources :messages, only: [:show, :create, :destroy]
end
Rails.application.routes.draw do
  root "contacts#index"

  get  "contacts/search", to: "contacts#search"
  resources :contacts, only: [:create, :destroy]
end
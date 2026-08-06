Rails.application.routes.draw do
  get "/swagger", to: redirect("/swagger.html")
  root "contacts#index"

  get  "contacts/search", to: "contacts#search"
  resources :contacts, only: [:create, :destroy]
end
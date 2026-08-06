Rails.application.routes.draw do
  get "/swagger", to: redirect("/swagger.html")
  root "semantic_search#index"
  get "search", to: "semantic_search#search"
  post "upload", to: "semantic_search#upload"
  get "collections", to: "semantic_search#collections"
end
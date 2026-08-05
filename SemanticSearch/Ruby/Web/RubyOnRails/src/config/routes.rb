Rails.application.routes.draw do
  root "semantic_search#index"
  get "search", to: "semantic_search#search"
  post "upload", to: "semantic_search#upload"
  get "collections", to: "semantic_search#collections"
end
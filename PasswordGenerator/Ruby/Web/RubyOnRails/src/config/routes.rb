Rails.application.routes.draw do
  get "/swagger", to: redirect("/swagger.html")
  root "password_entries#index"

  post "generate", to: "password_entries#generate"
end
Rails.application.routes.draw do
  get "/swagger", to: redirect("/swagger.html")
  root "calculator#index"

  post "calculate", to: "calculator#calculate"
end

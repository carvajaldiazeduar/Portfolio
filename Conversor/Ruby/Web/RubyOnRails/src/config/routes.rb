Rails.application.routes.draw do
  get "/swagger", to: redirect("/swagger.html")
  root "conversor#index"

  post "convert", to: "conversor#convert"
end
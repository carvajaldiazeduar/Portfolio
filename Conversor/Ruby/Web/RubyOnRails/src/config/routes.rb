Rails.application.routes.draw do
  root "conversor#index"

  post "convert", to: "conversor#convert"
end
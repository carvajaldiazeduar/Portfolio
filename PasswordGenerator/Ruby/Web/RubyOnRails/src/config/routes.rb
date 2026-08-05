Rails.application.routes.draw do
  root "password_entries#index"

  post "generate", to: "password_entries#generate"
end
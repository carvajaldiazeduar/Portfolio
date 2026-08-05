Rails.application.routes.draw do
  root "calculator#index"

  post "calculate", to: "calculator#calculate"
end

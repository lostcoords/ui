Rails.application.routes.draw do
  root "home#index"
  get "emoji-catalog", to: "home#emoji_catalog"
end

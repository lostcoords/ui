Rails.application.routes.draw do
  root "home#index"
  get "api", to: "home#api"
  get "llms", to: "home#llms"
  get "components/:component", to: "home#component", as: :component
  get "wada-license", to: "home#palette_license"
  get "tokens", to: "home#tokens"
  get "emoji-catalog", to: "home#emoji_catalog"
end

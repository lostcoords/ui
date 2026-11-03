Rails.application.routes.draw do
  root "home#index"
  get "api", to: "home#api"
  get "llms", to: "home#llms"
  get "components/:component", to: "home#component", as: :component
  get "blocks", to: "blocks#index"
  get "blocks/:block/preview", to: "blocks#preview", as: :block_preview
  get "blocks/:block", to: "blocks#show", as: :block
  get "wada-license", to: "home#palette_license"
  get "installation", to: "home#installation"
  get "starter", to: "home#starter"
  get "theming", to: "home#theming"
  get "tokens", to: "home#theming"
  get "emoji-catalog", to: "home#emoji_catalog"
end

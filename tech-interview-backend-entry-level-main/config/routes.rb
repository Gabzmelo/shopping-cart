require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  resources :products

  # Rotas para o carrinho
  post '/cart', to: 'carts#add_product', as: :add_product_to_cart
  get '/cart', to: 'carts#show', as: :show_cart
  post '/cart/add_item', to: 'carts#increment_item_quantity', as: :increment_cart_item_quantity
  delete '/cart/:product_id', to: 'carts#remove_product', as: :remove_product_from_cart

  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end

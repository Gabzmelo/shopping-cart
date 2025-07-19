require 'sidekiq/web'

Rails.application.routes.draw do
  resources :carts, only: [:create, :show, :destroy] do
    member do
      patch :update_item_quantity
      delete 'remove_item/:product_id', to: 'carts#destroy_item'
    end
  end
end


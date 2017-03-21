require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users

  root 'home#index'
  resources :products do
    collection { post :import_all }
  end
  resources :product_types do
    collection { get :product_errors}
    put :clear_errors, on: :member
  end

  resources :product_type_errors, only: %i(index destroy) do
    put 'toggle_solved', to: 'product_type_errors#toggle_solved', as: 'toggle_solved'
  end

  resources :wordpresses do
    post :import_products, on: :member
  end
  resources :aliexpresses
  resources :crawlers do
    put :enabled_status, on: :member
  end
  resources :crawler_logs, only: [:show, :index, :destroy]
  resources :orders, only: [:index, :show, :new, :create] do
    collection { post :track }
  end

  mount Sidekiq::Web => '/sidekiq'
end

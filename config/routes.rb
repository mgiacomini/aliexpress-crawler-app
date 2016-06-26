Rails.application.routes.draw do
  devise_for :users

  root 'home#index'
  resources :products do
    collection { post :import_all }
  end
  resources :product_types
  resources :wordpresses do
    post :import_products, on: :member
  end
  resources :aliexpresses
  resources :crawlers do
    put :enabled_status, on: :member
  end
end

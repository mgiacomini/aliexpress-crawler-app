Rails.application.routes.draw do
  root 'home#index'
  resources :products, except:[:new] do
    collection { post :import }
  end
  resources :configurations, only: [:index]
  resources :wordpresses
  resources :aliexpress_data
end

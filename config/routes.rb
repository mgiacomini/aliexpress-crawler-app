Rails.application.routes.draw do
  root 'home#index'
  resources :products, except:[:new] do
    collection { post :import }
  end
  resources :wordpresses
  resources :aliexpresses
end

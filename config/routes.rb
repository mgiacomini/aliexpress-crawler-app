Rails.application.routes.draw do
  get 'crawlers/index'

  root 'home#index'
  resources :products, except:[:new] do
    collection { post :import }
  end
  resources :wordpresses
  resources :aliexpresses
  resources :crawlers do
    member { post :run }
  end
end

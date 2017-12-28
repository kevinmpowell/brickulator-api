Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :lego_sets, only: [:index, :show] do
    resources :ebay_sales, only: [:index]
  end
end

require 'sidekiq/web'
# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  # resources :lego_sets, only: [:index, :show] do
  resources :lego_sets, only: [:index, :show], constraints: lambda { |request| request.xhr? } do # Locks down requests to only work via AJAX
    resources :ebay_sales, only: [:index]
  end
end

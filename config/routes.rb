require 'sidekiq/web'
# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  # TODO: Lock down all these requests behind xhr restrictions
  # TODO: Set CORS Headers at the environment level, so localhost:3000 can't make XHR requests to prod
  post 'signup', to: 'users#create'
  post 'auth/signin', to: 'authentication#authenticate'
  get 'auth/validate-token', to: 'authentication#validate_token'

  mount Sidekiq::Web => '/sidekiq'

  resources :lego_sets, only: [:index, :show] do
  # resources :lego_sets, only: [:index, :show], constraints: lambda { |request| request.xhr? } do # Locks down requests to only work via AJAX
    resources :ebay_sales, only: [:index]
  end
end

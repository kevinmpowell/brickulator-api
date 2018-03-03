require 'sidekiq/web'
# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  # TODO: Lock down all these requests behind xhr restrictions
  # TODO: Set CORS Headers at the environment level, so localhost:3000 can't make XHR requests to prod
  post 'subscribe', to: 'subscribers#create', constraints: lambda { |request| request.xhr? }
  post 'signup', to: 'users#create', constraints: lambda { |request| request.xhr? }
  post '/users/update', to: 'users#update', constraints: lambda { |request| request.xhr? }
  post 'auth/signin', to: 'authentication#authenticate', constraints: lambda { |request| request.xhr? }
  get 'auth/validate-token', to: 'authentication#validate_token', constraints: lambda { |request| request.xhr? }
  post 'password/forgot', to: 'passwords#forgot'
  post 'password/reset', to: 'passwords#reset'
  put 'password/update', to: 'passwords#update'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # Protect against timing attacks:
    # - See https://codahale.com/a-lesson-in-timing-attacks/
    # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
    # - Use & (do not use &&) so that it doesn't short circuit.
    # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  end
  mount Sidekiq::Web => '/sidekiq'

  # resources :lego_sets, only: [:index, :show] do
  resources :lego_sets, only: [:index, :show], constraints: lambda { |request| request.xhr? } do # Locks down requests to only work via AJAX
    resources :ebay_sales, only: [:index]
  end
end

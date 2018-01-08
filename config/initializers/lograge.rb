Rails.application.configure do
  config.lograge.base_controller_class = 'ActionController::API'
  config.lograge.custom_options = lambda do |event|
    { time: event.time }
  end
end

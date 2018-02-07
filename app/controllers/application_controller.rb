class ApplicationController < ActionController::API
  include Response
  include ExceptionHandler

  # called before every action on controllers
  before_action :authorize_request
  before_action :set_locale_variables
  @language = "en"
  @country = "US"
 
  attr_reader :current_user

  private

  def set_locale_variables
    @language = request.env['HTTP_ACCEPT_LANGUAGE'].downcase.scan(/^[a-z]{2}/).first rescue "en"
    @country = request.env['HTTP_ACCEPT_LANGUAGE'].downcase.scan(/[a-z]{2}$/).first rescue "us"
  end

  # Check for valid request token and return user
  def authorize_request
    @current_user = (AuthorizeApiRequest.new(request.headers).call)[:user]
  end
end

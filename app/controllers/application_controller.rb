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
    user_locales = http_accept_language.user_preferred_languages
    unless user_locales.empty?
      locale_with_region = user_locales.find{ |l| l.length == 5 }
      if (locale_with_region.nil?)
        # If only languages were passed, like 'en', 'de', 'es' only set the language
        @language = user_locales.first
      else
        # If language AND region was passed, like 'en-US', 'de-DE', 'en-GB', set language and country
        locale_data = locale_with_region.split('-')
        @language = locale_data.first
        @country = locale_data.last
      end
    end
  end

  # Check for valid request token and return user
  def authorize_request
    @current_user = (AuthorizeApiRequest.new(request.headers).call)[:user]
  end
end

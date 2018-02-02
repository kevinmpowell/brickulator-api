class AuthenticationController < ApplicationController
  skip_before_action :authorize_request, only: :authenticate
  # return auth token once user is authenticated
  def authenticate
    auth_token = AuthenticateUser.new(auth_params[:email], auth_params[:password]).call
    if auth_token
      user = User.select(:preferences, :plus_member).where({email: auth_params[:email]}).first
      preferences = user.preferences
      preferences[:plus_member] = user.plus_member
      rot13_json_response(auth_token: auth_token, preferences: preferences)
    end
  end

  def validate_token
    json_response(auth_token_valid: true) # The auth token will be sent in as a header, if it gets this far, it's valid, just return true
  end

  private

  def auth_params
    params.permit(:email, :password)
  end
end

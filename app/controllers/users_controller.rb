class UsersController < ApplicationController
  skip_before_action :authorize_request, only: [:create]
  # POST /signup
  # return authenticated token upon signup
  def create
    # Check if a user with that email already exists
    if User.find_by_email(user_params[:email])
      json_response({ message: Message.account_exists }, :unprocessable_entity)
    else
      user = User.create!(user_params)
      auth_token = AuthenticateUser.new(user.email, user.password).call
      response = { message: Message.account_created, auth_token: auth_token }
      json_response(response, :created)
    end
  end

  private

  def user_params
    params.permit(
      :name,
      :email,
      :password,
      :password_confirmation
    )
  end
end

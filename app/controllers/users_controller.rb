class UsersController < ApplicationController
  skip_before_action :authorize_request, only: [:create]
  # POST /signup
  # return authenticated token upon signup
  def create
    # Check if a user with that email already exists
    puts user_params[:account_type]
    if User.find_by_email(user_params[:email])
      json_response({ message: Message.account_exists }, :unprocessable_entity)
    else
      user = User.create!(user_params)
      auth_token = AuthenticateUser.new(user.email, user.password).call
      response = { message: Message.account_created, auth_token: auth_token }
      json_response(response, :created)
    end
  end

  def update
    preferences = JSON.parse(user_params[:preferences])
    @current_user.update_attributes({preferences: preferences})
    preferences = @current_user.reload.preferences
    preferences[:plus_member] = @current_user.plus_member
    rot13_json_response({preferences: preferences})
  end

  private

  def user_params
    params.permit(
      :name,
      :email,
      :password,
      :password_confirmation,
      :preferences,
      :account_type
    )
  end
end

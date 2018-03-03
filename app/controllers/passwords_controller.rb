class PasswordsController < ApplicationController
  skip_before_action :authorize_request, only: [:forgot, :reset]

  def forgot
    if user_params[:email].blank?
      return render json: {error: 'Email not present'}
    end

    user = User.find_by(email: user_params[:email].downcase)

    if user.present?
      user.generate_password_token!
      UserMailer.password_reset_email(user).deliver_later
      render json: {status: 'ok'}, status: :ok
    else
      render json: {error: ['Email address not found. Please check and try again.']}, status: :not_found
    end
  end

  def reset
    token = user_params[:reset_password_token].to_s

    if user_params[:email].blank?
      return render json: {error: 'Email not present'}
    end

    if user_params[:password] != user_params[:password_confirmation]
      return render json: {error: 'Password and Password confirmation do not match'}
    end

    user = User.find_by(reset_password_token: token)

    if user.present? && user.password_token_valid?
      if user.reset_password!(user_params[:password])
        render json: {status: 'ok'}, status: :ok
      else
        render json: {error: user.errors.full_messages}, status: :unprocessable_entity
      end
    else
      render json: {error:  ['Link not valid or expired. Try generating a new link.']}, status: :not_found
    end
  end

  def update
    if !user_params[:password].present? || !user_params[:password_confirmation].present?
      render json: {error: 'Password not present'}, status: :unprocessable_entity
      return
    end

    if user_params[:password] != user_params[:password_confirmation]
      return render json: {error: 'Password and Password confirmation do not match'}
    end

    if @current_user.reset_password!(user_params[:password])
      render json: {status: 'ok'}, status: :ok
    else
      render json: {errors: current_user.errors.full_messages}, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(
      :name,
      :email,
      :password,
      :password_confirmation,
      :preferences,
      :reset_password_token
    )
  end
end

class UserMailer < ApplicationMailer
  default from: 'support@brickulator.com'
   
  def password_reset_email(user)
    @user = user
    @reset_token  = user.reset_password_token
    @password_reset_url = ENV['PASSWORD_RESET_URL']
    mail(to: @user.email, subject: 'Brickulator Password Reset')
  end
end

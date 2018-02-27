class UsersController < ApplicationController
  skip_before_action :authorize_request, only: [:create]
  # POST /signup
  # return authenticated token upon signup
  def create
    # Check if a user with that email already exists
    if User.find_by_email(user_params[:email])
      json_response({ message: Message.account_exists }, :unprocessable_entity)
    else
      user = User.new(user_params)

      if user.valid?
        if account_params[:account_type] == "free"
          # Put them in the Brickulator Free Mailchimp Group
          MailchimpService.add_brickulator_free_subscriber(user.email)
          # Set default free member settings
          user.plus_member = false
          user.preferences = {
            "country"=>account_params[:country], 
            "currency"=>account_params[:currency]
          }

        elsif account_params[:account_type] == "plus"
          # Subscribe them to Brickulator Plus with stripe
          stripeCustomer = StripeService.subscribeCustomerToBrickulatorPlus(user.email, account_params[:stripe_token])
          user.stripe_id = stripeCustomer.id

          # Put them in the Brickulator Plus Mailchimp Group
          MailchimpService.add_brickulator_plus_subscriber(user.email)

          # Set default plus member settings
          user.plus_member = true
          user.preferences = {
            "country"=>account_params[:country], 
            "currency"=>account_params[:currency],
            "taxRate"=>"5",
            "enableTaxes"=>true, 
            "portletConfig"=>{
              "eCLN"=>true, 
              "eCLU"=>true, 
              "eSVN"=>true, 
              "eSVU"=>true, 
              "blCLN"=>true, 
              "blCLU"=>true, 
              "blSVN"=>true, 
              "blSVU"=>true, 
              "boCLN"=>true, 
              "boCLU"=>true, 
              "boSVN"=>true, 
              "boSVU"=>true
            }, 
            "enablePurchaseQuantity"=>true
          }
        end

        user.save!
        auth_token = AuthenticateUser.new(user.email, user.password).call
        preferences = user.preferences
        preferences[:plus_member] = user.plus_member
        response = { message: Message.account_created, auth_token: auth_token, preferences: preferences }
        rot13_json_response(response, :created)
      else
        json_response(user.errors.messages, :bad_request)
      end
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
      :preferences
    )
  end

  def account_params
    params.permit(
      :account_type,
      :country,
      :currency,
      :stripe_token
    )
  end
end

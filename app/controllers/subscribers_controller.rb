class SubscribersController < ApplicationController
  skip_before_action :authorize_request, only: [:create]

  # POST /subscribe
  def create
    gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
    puts subscriber_params[:email]
    gibbon.lists(ENV['MAILCHIMP_SUBSCRIBER_LIST_ID']).members.create(body: {email_address: subscriber_params[:email], status: "subscribed"})
  end

  private

  def subscriber_params
    params.permit(
      :email
    )
  end
end

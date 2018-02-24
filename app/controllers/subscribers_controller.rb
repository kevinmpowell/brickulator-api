class SubscribersController < ApplicationController
  skip_before_action :authorize_request, only: [:create]

  # POST /subscribe
  def create
    MailchimpService.subscribe_new_email_to_list(subscriber_params[:email])
  end

  private

  def subscriber_params
    params.permit(
      :email
    )
  end
end

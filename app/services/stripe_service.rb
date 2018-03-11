# app/lib/stripe_service.rb

class StripeService

  Stripe.api_key = ENV['STRIPE_SECRET_KEY']
  BRICKULATOR_PLUS_PLAN_NAME = ENV['STRIPE_BRICKULATOR_PLUS_PLAN_NAME']


  def self.createCustomerWithSavedPaymentToken email, token
    # Create a Customer:
    customer = Stripe::Customer.create(
      :email => email,
      :source => token,
    )
  end

  def self.subscribeCustomerToBrickulatorPlus email, token
    c = StripeService.createCustomerWithSavedPaymentToken(email, token)

    subscription = Stripe::Subscription.create({
        customer: c.id,
        items: [{plan: "brickulator-plus"}],
    })

    # Return the customer
    c
  end
end

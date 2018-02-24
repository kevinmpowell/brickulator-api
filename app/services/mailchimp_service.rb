# app/lib/mailchimp_service.rb

class MailchimpService
  API_KEY = ENV['MAILCHIMP_API_KEY']
  BRICKULATOR_SUBSCRIBER_LIST_ID = ENV['MAILCHIMP_SUBSCRIBER_LIST_ID']
  BRICKULATOR_PLUS_INTEREST_ID = ENV['MAILCHIMP_BRICKULATOR_PLUS_INTEREST_ID']
  BRICKULATOR_FREE_INTEREST_ID = ENV['MAILCHIMP_BRICKULATOR_FREE_INTEREST_ID']

  def self.unsubscribe_user_by_email email
    gibbon = Gibbon::Request.new(api_key: API_KEY)
    gibbon.lists(BRICKULATOR_SUBSCRIBER_LIST_ID).members(Digest::MD5.hexdigest(email)).upsert(
      {
          body: {
              email_address: email,
              status: "unsubscribed"
          }
      })
  end

  def self.subscribe_user_by_email email
    gibbon = Gibbon::Request.new(api_key: API_KEY)
    gibbon.lists(BRICKULATOR_SUBSCRIBER_LIST_ID).members(Digest::MD5.hexdigest(email)).upsert(
      {
          body: {
              email_address: email,
              status: "subscribed"
          }
      })
  end

  def self.add_brickulator_free_subscriber email
    gibbon = Gibbon::Request.new(api_key: API_KEY)
    gibbon.lists(BRICKULATOR_SUBSCRIBER_LIST_ID).members(Digest::MD5.hexdigest(email)).upsert(
      {
          body: {
              email_address: email,
              interests: {
                "#{BRICKULATOR_FREE_INTEREST_ID}": true, 
                "#{BRICKULATOR_PLUS_INTEREST_ID}": false
              }
          }
      })
  end

  def self.add_brickulator_plus_subscriber email
    gibbon = Gibbon::Request.new(api_key: API_KEY)
    gibbon.lists(BRICKULATOR_SUBSCRIBER_LIST_ID).members(Digest::MD5.hexdigest(email)).upsert(
      {
          body: {
              email_address: email,
              interests: {
                "#{BRICKULATOR_FREE_INTEREST_ID}": false, 
                "#{BRICKULATOR_PLUS_INTEREST_ID}": true
              }
          }
      })
  end

  def self.remove_subscriber_from_free_and_plus_groups email
    gibbon = Gibbon::Request.new(api_key: API_KEY)
    gibbon.lists(BRICKULATOR_SUBSCRIBER_LIST_ID).members(Digest::MD5.hexdigest(email)).upsert(
      {
          body: {
              email_address: email,
              interests: {
                "#{BRICKULATOR_FREE_INTEREST_ID}": false, 
                "#{BRICKULATOR_PLUS_INTEREST_ID}": false
              }
          }
      })
  end

end

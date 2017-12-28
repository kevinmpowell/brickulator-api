# spec/factories/ebay_sales.rb
FactoryBot.define do
  factory :ebay_sale do
    avg_sales 843.5
    high_sale 903.5
    low_sale 744.3
    listings 50
    date Time.now
    lego_set_id nil
  end
end

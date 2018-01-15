class ChangeEbayValueModel < ActiveRecord::Migration[5.1]
  def change
    drop_table :ebay_sales do |t|
      t.datetime :date
      t.float :avg_sales
      t.float :high_sale
      t.float :low_sale
      t.integer :listings
      t.references :lego_set, foreign_key: true

      t.timestamps
    end

    create_table :ebay_values do |t|
      t.datetime :retrieved_at
      t.integer :complete_set_completed_listing_used_listings_count
      t.float :complete_set_completed_listing_used_avg_price
      t.float :complete_set_completed_listing_used_median_price
      t.float :complete_set_completed_listing_used_high_price
      t.float :complete_set_completed_listing_used_low_price
      t.float :complete_set_completed_listing_used_time_on_market_low
      t.float :complete_set_completed_listing_used_time_on_market_high
      t.float :complete_set_completed_listing_used_time_on_market_avg
      t.float :complete_set_completed_listing_used_time_on_market_median
      t.integer :complete_set_completed_listing_new_listings_count
      t.float :complete_set_completed_listing_new_avg_price
      t.float :complete_set_completed_listing_new_median_price
      t.float :complete_set_completed_listing_new_high_price
      t.float :complete_set_completed_listing_new_low_price
      t.float :complete_set_completed_listing_new_time_on_market_low
      t.float :complete_set_completed_listing_new_time_on_market_high
      t.float :complete_set_completed_listing_new_time_on_market_avg
      t.float :complete_set_completed_listing_new_time_on_market_median
      t.boolean :most_recent, :default => false, :null => false
      t.references :lego_set, foreign_key: true

      t.timestamps
    end
    add_index :ebay_values, :most_recent, where: :most_recent  # partial index
  end
end

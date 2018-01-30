class AddColumnsToEbayValue < ActiveRecord::Migration[5.1]
  def change
    add_column :ebay_values, :complete_set_used_listings_count, :integer
    add_column :ebay_values, :complete_set_used_avg_price, :float
    add_column :ebay_values, :complete_set_used_median_price, :float
    add_column :ebay_values, :complete_set_used_high_price, :float
    add_column :ebay_values, :complete_set_used_low_price, :float

    add_column :ebay_values, :complete_set_new_listings_count, :integer
    add_column :ebay_values, :complete_set_new_avg_price, :float
    add_column :ebay_values, :complete_set_new_median_price, :float
    add_column :ebay_values, :complete_set_new_high_price, :float
    add_column :ebay_values, :complete_set_new_low_price, :float
  end
end

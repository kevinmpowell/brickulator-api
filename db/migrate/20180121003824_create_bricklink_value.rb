class CreateBricklinkValue < ActiveRecord::Migration[5.1]
  def change
    create_table :bricklink_values do |t|
      t.datetime :retrieved_at
      t.integer :complete_set_new_listings_count
      t.float :complete_set_new_avg_price
      t.float :complete_set_new_median_price 
      t.float :complete_set_new_high_price
      t.float :complete_set_new_low_price
      t.integer :complete_set_used_listings_count
      t.float :complete_set_used_avg_price
      t.float :complete_set_used_median_price 
      t.float :complete_set_used_high_price
      t.float :complete_set_used_low_price
      t.integer :complete_set_completed_listing_new_listings_count
      t.float :complete_set_completed_listing_new_avg_price
      t.float :complete_set_completed_listing_new_median_price
      t.float :complete_set_completed_listing_new_high_price
      t.float :complete_set_completed_listing_new_low_price
      t.integer :complete_set_completed_listing_used_listings_count
      t.float :complete_set_completed_listing_used_avg_price
      t.float :complete_set_completed_listing_used_median_price
      t.float :complete_set_completed_listing_used_high_price
      t.float :complete_set_completed_listing_used_low_price
      t.float :part_out_value_last_six_months_used
      t.float :part_out_value_last_six_months_new
      t.float :part_out_value_current_used
      t.float :part_out_value_current_new
      t.boolean :most_recent, :default => false, :null => false
      t.references :lego_set, foreign_key: true

      t.timestamps
    end
    add_index :bricklink_values, :most_recent, where: :most_recent  # partial index
  end
end
